// Theme Toggle Functionality
(function() {
  'use strict';

  function readTheme() {
    try {
      return localStorage.getItem('theme') === 'dark' ? 'dark' : 'light';
    } catch (error) {
      return 'light';
    }
  }

  function saveTheme(theme) {
    try {
      localStorage.setItem('theme', theme);
    } catch (error) {
      // The current page still changes theme when storage is unavailable.
    }
  }

  function initTheme() {
    var savedTheme = readTheme();
    document.documentElement.setAttribute('data-bs-theme', savedTheme);
    updateToggleButton(savedTheme);
  }

  function toggleTheme() {
    var html = document.documentElement;
    var currentTheme = html.getAttribute('data-bs-theme') || 'light';
    var newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    html.setAttribute('data-bs-theme', newTheme);
    saveTheme(newTheme);
    updateToggleButton(newTheme);
  }

  function updateToggleButton(theme) {
    var button = document.getElementById('theme-toggle');
    if (!button) return;
    var icon = button.querySelector('i');
    if (icon) icon.className = theme === 'dark' ? 'bi bi-sun-fill' : 'bi bi-moon-stars';
    button.setAttribute('aria-pressed', String(theme === 'dark'));
    button.setAttribute('aria-label', theme === 'dark' ? 'Switch to light theme' : 'Switch to dark theme');
  }

  document.addEventListener('DOMContentLoaded', function() {
    var toggleButton = document.getElementById('theme-toggle');
    if (toggleButton) toggleButton.addEventListener('click', toggleTheme);
  });

  initTheme();
})();
