package fizzy

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"sync"

	"github.com/zalando/go-keyring"
)

const serviceName = "fizzy-sdk"

// Credentials holds session tokens and metadata.
type Credentials struct {
	SessionToken string `json:"session_token"`
	UserID       string `json:"user_id,omitempty"`
}

// TokenProvider is the interface for obtaining access tokens.
type TokenProvider interface {
	// AccessToken returns a valid access token.
	AccessToken(ctx context.Context) (string, error)
}

// StaticTokenProvider provides a fixed token (e.g., from FIZZY_TOKEN env var).
type StaticTokenProvider struct {
	Token string
}

// AccessToken returns the static token.
func (p *StaticTokenProvider) AccessToken(ctx context.Context) (string, error) {
	return p.Token, nil
}

// CredentialStore handles secure credential storage.
type CredentialStore struct {
	useKeyring  bool
	fallbackDir string
}

// NewCredentialStore creates a credential store.
// It prefers the system keyring if available, falling back to file storage.
func NewCredentialStore(fallbackDir string) *CredentialStore {
	// Skip keyring for tests or when explicitly disabled
	if os.Getenv("FIZZY_NO_KEYRING") != "" {
		return &CredentialStore{useKeyring: false, fallbackDir: fallbackDir}
	}

	// Test if keyring is available
	testKey := "fizzy-sdk::test"
	err := keyring.Set(serviceName, testKey, "test")
	if err == nil {
		_ = keyring.Delete(serviceName, testKey) // Cleanup test key
		return &CredentialStore{useKeyring: true, fallbackDir: fallbackDir}
	}
	return &CredentialStore{useKeyring: false, fallbackDir: fallbackDir}
}

// keyFor returns the storage key for an origin.
func keyFor(origin string) string {
	return fmt.Sprintf("fizzy-sdk::%s", origin)
}

// Load retrieves credentials for the given origin.
func (s *CredentialStore) Load(origin string) (*Credentials, error) {
	if s.useKeyring {
		return s.loadFromKeyring(origin)
	}
	return s.loadFromFile(origin)
}

// Save stores credentials for the given origin.
func (s *CredentialStore) Save(origin string, creds *Credentials) error {
	if s.useKeyring {
		return s.saveToKeyring(origin, creds)
	}
	return s.saveToFile(origin, creds)
}

// Delete removes credentials for the given origin.
func (s *CredentialStore) Delete(origin string) error {
	if s.useKeyring {
		return keyring.Delete(serviceName, keyFor(origin))
	}
	return s.deleteFile(origin)
}

// UsingKeyring returns true if the store is using the system keyring.
func (s *CredentialStore) UsingKeyring() bool {
	return s.useKeyring
}

func (s *CredentialStore) loadFromKeyring(origin string) (*Credentials, error) {
	data, err := keyring.Get(serviceName, keyFor(origin))
	if err != nil {
		return nil, fmt.Errorf("credentials not found: %w", err)
	}

	var creds Credentials
	if err := json.Unmarshal([]byte(data), &creds); err != nil {
		return nil, fmt.Errorf("invalid credentials: %w", err)
	}
	return &creds, nil
}

func (s *CredentialStore) saveToKeyring(origin string, creds *Credentials) error {
	data, err := json.Marshal(creds)
	if err != nil {
		return err
	}
	return keyring.Set(serviceName, keyFor(origin), string(data))
}

func (s *CredentialStore) credentialsPath() string {
	return s.fallbackDir + "/credentials.json"
}

func (s *CredentialStore) loadAllFromFile() (map[string]*Credentials, error) {
	data, err := os.ReadFile(s.credentialsPath())
	if err != nil {
		if os.IsNotExist(err) {
			return make(map[string]*Credentials), nil
		}
		return nil, err
	}

	var all map[string]*Credentials
	if err := json.Unmarshal(data, &all); err != nil {
		return nil, err
	}
	return all, nil
}

func (s *CredentialStore) saveAllToFile(all map[string]*Credentials) error {
	if err := os.MkdirAll(s.fallbackDir, 0700); err != nil {
		return err
	}

	data, err := json.MarshalIndent(all, "", "  ")
	if err != nil {
		return err
	}

	// Atomic write using unique temp file to avoid collisions
	tmpFile, err := os.CreateTemp(s.fallbackDir, "credentials-*.tmp")
	if err != nil {
		return err
	}
	tmpPath := tmpFile.Name()
	if _, err := tmpFile.Write(data); err != nil {
		_ = tmpFile.Close()
		_ = os.Remove(tmpPath)
		return err
	}
	if err := tmpFile.Chmod(0600); err != nil {
		_ = tmpFile.Close()
		_ = os.Remove(tmpPath)
		return err
	}
	if err := tmpFile.Close(); err != nil {
		_ = os.Remove(tmpPath)
		return err
	}
	if err := os.Rename(tmpPath, s.credentialsPath()); err != nil {
		_ = os.Remove(tmpPath)
		return err
	}
	return nil
}

func (s *CredentialStore) loadFromFile(origin string) (*Credentials, error) {
	all, err := s.loadAllFromFile()
	if err != nil {
		return nil, err
	}

	creds, ok := all[origin]
	if !ok {
		return nil, fmt.Errorf("credentials not found for %s", origin)
	}
	return creds, nil
}

func (s *CredentialStore) saveToFile(origin string, creds *Credentials) error {
	all, err := s.loadAllFromFile()
	if err != nil {
		return err
	}

	all[origin] = creds
	return s.saveAllToFile(all)
}

func (s *CredentialStore) deleteFile(origin string) error {
	all, err := s.loadAllFromFile()
	if err != nil {
		return err
	}

	delete(all, origin)
	return s.saveAllToFile(all)
}

// AuthManager handles session token management for Fizzy.
type AuthManager struct {
	cfg   *Config
	store *CredentialStore
	mu    sync.Mutex
}

// NewAuthManager creates a new auth manager.
func NewAuthManager(cfg *Config) *AuthManager {
	return &AuthManager{
		cfg:   cfg,
		store: NewCredentialStore(globalConfigDir()),
	}
}

// NewAuthManagerWithStore creates an auth manager with a custom credential store.
func NewAuthManagerWithStore(cfg *Config, store *CredentialStore) *AuthManager {
	return &AuthManager{
		cfg:   cfg,
		store: store,
	}
}

// AccessToken returns a valid access token.
// If FIZZY_TOKEN env var is set, it's used directly.
func (m *AuthManager) AccessToken(ctx context.Context) (string, error) {
	// Check for FIZZY_TOKEN environment variable first
	if token := os.Getenv("FIZZY_TOKEN"); token != "" {
		return token, nil
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	origin := NormalizeBaseURL(m.cfg.BaseURL)
	creds, err := m.store.Load(origin)
	if err != nil {
		return "", ErrAuth("Not authenticated")
	}

	return creds.SessionToken, nil
}

// IsAuthenticated checks if there are valid credentials.
func (m *AuthManager) IsAuthenticated() bool {
	// Check for FIZZY_TOKEN environment variable first
	if os.Getenv("FIZZY_TOKEN") != "" {
		return true
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	origin := NormalizeBaseURL(m.cfg.BaseURL)
	creds, err := m.store.Load(origin)
	if err != nil {
		return false
	}
	return creds.SessionToken != ""
}

// Logout removes stored credentials.
func (m *AuthManager) Logout() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	origin := NormalizeBaseURL(m.cfg.BaseURL)
	return m.store.Delete(origin)
}

// GetUserID returns the stored user ID.
func (m *AuthManager) GetUserID() string {
	m.mu.Lock()
	defer m.mu.Unlock()

	origin := NormalizeBaseURL(m.cfg.BaseURL)
	creds, err := m.store.Load(origin)
	if err != nil {
		return ""
	}
	return creds.UserID
}

// SetUserID stores the user ID.
func (m *AuthManager) SetUserID(userID string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	origin := NormalizeBaseURL(m.cfg.BaseURL)
	creds, err := m.store.Load(origin)
	if err != nil {
		return err
	}
	creds.UserID = userID
	return m.store.Save(origin, creds)
}

// Store returns the credential store.
func (m *AuthManager) Store() *CredentialStore {
	return m.store
}

// SaveSessionToken stores a session token obtained from login.
func (m *AuthManager) SaveSessionToken(token string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	origin := NormalizeBaseURL(m.cfg.BaseURL)
	creds := &Credentials{SessionToken: token}
	return m.store.Save(origin, creds)
}
