package fizzy

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

// MagicLinkFlow orchestrates passwordless login via magic links.
// The flow is:
//  1. CreateSession — sends a magic link to the user's email
//  2. User clicks the magic link in their email
//  3. RedeemMagicLink — exchanges the magic link token for a session token
type MagicLinkFlow struct {
	baseURL    string
	httpClient *http.Client
}

// NewMagicLinkFlow creates a new magic link flow.
func NewMagicLinkFlow(baseURL string, httpClient *http.Client) *MagicLinkFlow {
	if httpClient == nil {
		httpClient = &http.Client{}
	}
	return &MagicLinkFlow{
		baseURL:    NormalizeBaseURL(baseURL),
		httpClient: httpClient,
	}
}

// CreateSessionRequest is the request body for creating a session.
type CreateSessionRequest struct {
	Email string `json:"email"`
}

// CreateSessionResponse is the response from creating a session.
type CreateSessionResponse struct {
	Message string `json:"message"`
}

// CreateSession initiates the magic link flow by sending a magic link email.
func (f *MagicLinkFlow) CreateSession(ctx context.Context, email string) (*CreateSessionResponse, error) {
	body, err := json.Marshal(CreateSessionRequest{Email: email})
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	url := f.baseURL + "/api/v1/sessions"
	req, err := http.NewRequestWithContext(ctx, "POST", url, strings.NewReader(string(body)))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	resp, err := f.httpClient.Do(req)
	if err != nil {
		return nil, ErrNetwork(err)
	}
	defer func() { _ = resp.Body.Close() }()

	respBody, err := limitedReadAll(resp.Body, MaxResponseBodyBytes)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		return nil, ErrAPI(resp.StatusCode, fmt.Sprintf("create session failed: HTTP %d", resp.StatusCode))
	}

	var result CreateSessionResponse
	if err := json.Unmarshal(respBody, &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &result, nil
}

// RedeemMagicLinkRequest is the request body for redeeming a magic link.
type RedeemMagicLinkRequest struct {
	Token string `json:"token"`
}

// RedeemMagicLinkResponse is the response from redeeming a magic link.
type RedeemMagicLinkResponse struct {
	SessionToken string `json:"session_token"`
	UserID       string `json:"user_id"`
}

// RedeemMagicLink exchanges a magic link token for a session token.
func (f *MagicLinkFlow) RedeemMagicLink(ctx context.Context, token string) (*RedeemMagicLinkResponse, error) {
	body, err := json.Marshal(RedeemMagicLinkRequest{Token: token})
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	url := f.baseURL + "/api/v1/sessions/redeem"
	req, err := http.NewRequestWithContext(ctx, "POST", url, strings.NewReader(string(body)))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	resp, err := f.httpClient.Do(req)
	if err != nil {
		return nil, ErrNetwork(err)
	}
	defer func() { _ = resp.Body.Close() }()

	respBody, err := limitedReadAll(resp.Body, MaxResponseBodyBytes)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, ErrAPI(resp.StatusCode, fmt.Sprintf("redeem magic link failed: HTTP %d", resp.StatusCode))
	}

	var result RedeemMagicLinkResponse
	if err := json.Unmarshal(respBody, &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &result, nil
}

// Login performs the full magic link login flow and stores the session token.
// After calling CreateSession, the caller must obtain the magic link token
// (e.g., by prompting the user to check their email), then call RedeemMagicLink.
// This method handles the final step of storing the token.
func (f *MagicLinkFlow) Login(ctx context.Context, authManager *AuthManager, magicLinkToken string) error {
	result, err := f.RedeemMagicLink(ctx, magicLinkToken)
	if err != nil {
		return err
	}

	if err := authManager.SaveSessionToken(result.SessionToken); err != nil {
		return fmt.Errorf("failed to save session token: %w", err)
	}

	if result.UserID != "" {
		if err := authManager.SetUserID(result.UserID); err != nil {
			return fmt.Errorf("failed to save user ID: %w", err)
		}
	}

	return nil
}
