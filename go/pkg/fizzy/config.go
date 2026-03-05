package fizzy

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Config holds the resolved configuration for API access.
type Config struct {
	// BaseURL is the API base URL (e.g., "https://fizzy.do").
	BaseURL string `json:"base_url"`

	// Account is the default account identifier.
	Account string `json:"account"`

	// CacheDir is the directory for HTTP cache storage.
	CacheDir string `json:"cache_dir"`

	// CacheEnabled controls whether HTTP caching is enabled.
	CacheEnabled bool `json:"cache_enabled"`
}

// DefaultConfig returns a Config with sensible defaults.
func DefaultConfig() *Config {
	cacheDir := os.Getenv("XDG_CACHE_HOME")
	if cacheDir == "" {
		home, _ := os.UserHomeDir()
		cacheDir = filepath.Join(home, ".cache")
	}

	return &Config{
		BaseURL:      "https://fizzy.do",
		CacheDir:     filepath.Join(cacheDir, "fizzy"),
		CacheEnabled: false,
	}
}

// LoadConfig loads configuration from a JSON file.
func LoadConfig(path string) (*Config, error) {
	cfg := DefaultConfig()

	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return cfg, nil
		}
		return nil, err
	}

	if err := json.Unmarshal(data, cfg); err != nil {
		return nil, fmt.Errorf("invalid config: %w", err)
	}

	return cfg, nil
}

// LoadConfigFromEnv loads configuration from environment variables.
// Environment variables override any values already set in the config.
func (c *Config) LoadConfigFromEnv() {
	if v := os.Getenv("FIZZY_API_URL"); v != "" {
		c.BaseURL = v
	}
	if v := os.Getenv("FIZZY_ACCOUNT"); v != "" {
		c.Account = v
	}
	if v := os.Getenv("FIZZY_CACHE_DIR"); v != "" {
		c.CacheDir = v
	}
	if v := os.Getenv("FIZZY_CACHE_ENABLED"); v != "" {
		c.CacheEnabled = strings.ToLower(v) == "true" || v == "1"
	}
}

// NormalizeBaseURL ensures consistent URL format (no trailing slash).
func NormalizeBaseURL(url string) string {
	return strings.TrimSuffix(url, "/")
}

// globalConfigDir returns the global config directory path.
func globalConfigDir() string {
	configDir := os.Getenv("XDG_CONFIG_HOME")
	if configDir == "" {
		home, _ := os.UserHomeDir()
		configDir = filepath.Join(home, ".config")
	}
	return filepath.Join(configDir, "fizzy")
}
