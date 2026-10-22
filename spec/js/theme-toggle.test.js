const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const source = fs.readFileSync(
  path.join(__dirname, '../../lib/oxidized/web/public/scripts/theme-toggle.js'),
  'utf8'
);

function setup(storage, initialTheme) {
  const documentListeners = {};
  const buttonListeners = {};
  const attrs = {};
  const icon = { className: '' };
  const button = {
    setAttribute: (name, value) => { attrs[name] = value; },
    querySelector: () => icon,
    addEventListener: (name, listener) => { buttonListeners[name] = listener; }
  };
  const documentElement = {
    setAttribute: (name, value) => { documentElement[name] = value; },
    getAttribute: (name) => documentElement[name] || initialTheme || null
  };
  const document = {
    documentElement,
    addEventListener: (name, listener) => { documentListeners[name] = listener; },
    getElementById: () => button
  };

  vm.runInNewContext(source, { document, localStorage: storage });
  documentListeners.DOMContentLoaded();
  return { attrs, buttonListeners, documentElement, icon };
}

test('saved dark theme initializes matching icon and accessible state', () => {
  const values = new Map([['theme', 'dark']]);
  const ui = setup({ getItem: (key) => values.get(key), setItem: (key, value) => values.set(key, value) });

  assert.equal(ui.documentElement['data-bs-theme'], 'dark');
  assert.equal(ui.icon.className, 'bi bi-sun-fill');
  assert.equal(ui.attrs['aria-pressed'], 'true');
  assert.equal(ui.attrs['aria-label'], 'Switch to light theme');
});

test('theme toggle saves the new theme and updates accessible state', () => {
  const values = new Map([['theme', 'light']]);
  const ui = setup({ getItem: (key) => values.get(key), setItem: (key, value) => values.set(key, value) });
  ui.buttonListeners.click();

  assert.equal(ui.documentElement['data-bs-theme'], 'dark');
  assert.equal(values.get('theme'), 'dark');
  assert.equal(ui.attrs['aria-pressed'], 'true');
});

test('theme still toggles when browser storage is unavailable', () => {
  const storage = {
    getItem() { throw new Error('storage disabled'); },
    setItem() { throw new Error('storage disabled'); }
  };
  const ui = setup(storage);
  ui.buttonListeners.click();

  assert.equal(ui.documentElement['data-bs-theme'], 'dark');
  assert.equal(ui.attrs['aria-label'], 'Switch to light theme');
});
