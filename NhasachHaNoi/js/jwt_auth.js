/**
 * JWT Authentication Helper for eLibrary Frontend
 * Handles JWT token storage and authenticated API requests
 */
const JWTAuth = {
    // Storage key for JWT token
    TOKEN_KEY: 'jwt_token',

    /**
     * Store JWT token in localStorage
     * @param {string} token - The JWT token to store
     */
    setToken: function(token) {
        if (token) {
            localStorage.setItem(this.TOKEN_KEY, token);
        }
    },

    /**
     * Get JWT token from localStorage
     * @returns {string|null} The stored JWT token or null
     */
    getToken: function() {
        return localStorage.getItem(this.TOKEN_KEY);
    },

    /**
     * Remove JWT token from localStorage (logout)
     */
    clearToken: function() {
        localStorage.removeItem(this.TOKEN_KEY);
    },

    /**
     * Check if user has a valid token stored
     * @returns {boolean} True if token exists
     */
    hasToken: function() {
        return this.getToken() !== null;
    },

    /**
     * Decode JWT token payload (without verification)
     * @param {string} token - The JWT token to decode
     * @returns {object|null} Decoded payload or null if invalid
     */
    decodeToken: function(token) {
        try {
            if (!token) return null;
            const parts = token.split('.');
            if (parts.length !== 3) return null;
            const payload = parts[1];
            const decoded = atob(payload.replace(/-/g, '+').replace(/_/g, '/'));
            return JSON.parse(decoded);
        } catch (e) {
            console.error('Error decoding JWT token:', e);
            return null;
        }
    },

    /**
     * Check if token is expired
     * @returns {boolean} True if token is expired or invalid
     */
    isTokenExpired: function() {
        const token = this.getToken();
        if (!token) return true;

        const payload = this.decodeToken(token);
        if (!payload || !payload.exp) return true;

        // Check if current time is past expiration
        const currentTime = Math.floor(Date.now() / 1000);
        return currentTime >= payload.exp;
    },

    /**
     * Get token expiration date
     * @returns {Date|null} Expiration date or null
     */
    getTokenExpiry: function() {
        const token = this.getToken();
        if (!token) return null;

        const payload = this.decodeToken(token);
        if (!payload || !payload.exp) return null;

        return new Date(payload.exp * 1000);
    },

    /**
     * Get current user data from token
     * @returns {object|null} User data or null
     */
    getCurrentUser: function() {
        const token = this.getToken();
        if (!token) return null;

        const payload = this.decodeToken(token);
        if (!payload || !payload.data) return null;

        return payload.data;
    },

    /**
     * Make authenticated fetch request with JWT token
     * @param {string} url - The URL to fetch
     * @param {object} options - Fetch options
     * @returns {Promise} Fetch promise
     */
    authFetch: function(url, options = {}) {
        const token = this.getToken();

        // Initialize headers if not present
        options.headers = options.headers || {};

        // Add Authorization header if token exists
        if (token) {
            options.headers['Authorization'] = 'Bearer ' + token;
        }

        // Set Content-Type for JSON if not already set and we have a body
        if (options.body && !options.headers['Content-Type']) {
            options.headers['Content-Type'] = 'application/json';
        }

        return fetch(url, options).then(response => {
            // Handle 401 Unauthorized - token may be expired
            if (response.status === 401) {
                this.clearToken();
                // Optionally redirect to login
                // window.location.href = 'dangnhap.php';
            }
            return response;
        });
    },

    /**
     * Login via API and store token
     * @param {string} username - Username
     * @param {string} password - Password
     * @param {string} apiUrl - API login URL (default: api/login.php)
     * @returns {Promise} Promise resolving to login result
     */
    login: function(username, password, apiUrl = 'api/login.php') {
        return fetch(apiUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ username, password })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success && data.token) {
                this.setToken(data.token);
            }
            return data;
        });
    },

    /**
     * Logout - clear token and optionally redirect
     * @param {string} redirectUrl - URL to redirect after logout (optional)
     */
    logout: function(redirectUrl = null) {
        this.clearToken();
        if (redirectUrl) {
            window.location.href = redirectUrl;
        }
    },

    /**
     * Initialize - sync token from PHP session if available
     * Called when page loads to sync PHP session token with localStorage
     */
    init: function() {
        // Check if token is expired and clear if so
        if (this.isTokenExpired()) {
            this.clearToken();
        }
    }
};

// Auto-initialize when script loads
document.addEventListener('DOMContentLoaded', function() {
    JWTAuth.init();
});
