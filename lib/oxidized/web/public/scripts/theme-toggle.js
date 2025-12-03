// Theme Toggle Functionality
(function() {
  'use strict';

  /**
   * Initialize theme on page load
   * Retrieves saved theme from localStorage or defaults to 'light'
   */
  function initTheme() {
    const savedTheme = localStorage.getItem('theme') || 'light';
    document.documentElement.setAttribute('data-bs-theme', savedTheme);
    updateToggleButton(savedTheme);
  }

  /**
   * Toggle between light and dark theme
   * Saves the new theme preference to localStorage
   */
  function toggleTheme() {
    const html = document.documentElement;
    const currentTheme = html.getAttribute('data-bs-theme') || 'light';
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    
    html.setAttribute('data-bs-theme', newTheme);
    localStorage.setItem('theme', newTheme);
    updateToggleButton(newTheme);
  }

  /**
   * Update the toggle button icon based on current theme
   * @param {string} theme - Current theme ('light' or 'dark')
   */
  function updateToggleButton(theme) {
    const button = document.getElementById('theme-toggle');
    if (button) {
      const icon = button.querySelector('i');
      if (icon) {
        icon.className = theme === 'dark' ? 'bi bi-sun-fill' : 'bi bi-moon-fill';
      }
    }
  }

  /**
   * Add event listener when DOM is fully loaded
   */
  document.addEventListener('DOMContentLoaded', function() {
    const toggleButton = document.getElementById('theme-toggle');
    if (toggleButton) {
      toggleButton.addEventListener('click', toggleTheme);
    }
  });

  // Initialize theme immediately to prevent flash of wrong theme
  initTheme();
})();