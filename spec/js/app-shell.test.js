const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const source = fs.readFileSync(
  path.join(__dirname, '../../lib/oxidized/web/public/scripts/app-shell.js'),
  'utf8'
);

function createClassList() {
  const values = new Set();
  return {
    add: (value) => values.add(value),
    remove: (value) => values.delete(value),
    contains: (value) => values.has(value),
    toggle(value) {
      if (values.has(value)) {
        values.delete(value);
        return false;
      }
      values.add(value);
      return true;
    }
  };
}

function setup() {
  const documentListeners = {};
  const buttonListeners = {};
  const linkListeners = {};
  const attributes = {};
  const toggle = {
    setAttribute: (name, value) => { attributes[name] = value; },
    addEventListener: (name, listener) => { buttonListeners[name] = listener; },
    contains: (target) => target === toggle,
    focus() { toggle.focused = true; }
  };
  const link = {
    addEventListener: (name, listener) => { linkListeners[name] = listener; },
    focus() { link.focused = true; }
  };
  const search = { focus() { search.focused = true; } };
  const sidebar = {
    inert: false,
    setAttribute: (name, value) => { sidebar[name] = value; },
    querySelector: () => link,
    contains: (target) => target === link
  };
  const document = {
    body: { classList: createClassList() },
    addEventListener: (name, listener) => { documentListeners[name] = listener; },
    getElementById: (id) => ({ 'sidebar-toggle': toggle, 'app-sidebar': sidebar,
      'global-config-search': search }[id] || null),
    querySelector: () => ({ href: '#global-config-search', ...link })
  };
  const windowListeners = {};
  let isMobile = true;
  const window = {
    matchMedia: () => ({ matches: isMobile }),
    addEventListener: (name, listener) => { windowListeners[name] = listener; }
  };

  vm.runInNewContext(source, { document, window });
  documentListeners.DOMContentLoaded();

  return { document, documentListeners, buttonListeners, linkListeners, attributes,
    toggle, sidebar, search, windowListeners, setMobile(value) { isMobile = value; } };
}

test('mobile menu opens with synchronized accessibility state and focus', () => {
  const ui = setup();
  ui.buttonListeners.click();

  assert.equal(ui.document.body.classList.contains('sidebar-open'), true);
  assert.equal(ui.attributes['aria-expanded'], 'true');
  assert.equal(ui.sidebar['aria-hidden'], 'false');
  assert.equal(ui.sidebar.inert, false);
  assert.equal(ui.sidebar.querySelector().focused, true);
});

test('Escape closes the menu and returns focus to its trigger', () => {
  const ui = setup();
  ui.buttonListeners.click();
  ui.documentListeners.keydown({ key: 'Escape' });

  assert.equal(ui.document.body.classList.contains('sidebar-open'), false);
  assert.equal(ui.attributes['aria-expanded'], 'false');
  assert.equal(ui.sidebar['aria-hidden'], 'true');
  assert.equal(ui.sidebar.inert, true);
  assert.equal(ui.toggle.focused, true);
});

test('outside click closes the mobile menu', () => {
  const ui = setup();
  ui.buttonListeners.click();
  ui.documentListeners.click({ target: {} });

  assert.equal(ui.document.body.classList.contains('sidebar-open'), false);
  assert.equal(ui.attributes['aria-expanded'], 'false');
});

test('configuration search navigation focuses search and closes the menu', () => {
  const ui = setup();
  ui.buttonListeners.click();
  let prevented = false;
  ui.linkListeners.click({ preventDefault() { prevented = true; } });

  assert.equal(prevented, true);
  assert.equal(ui.search.focused, true);
  assert.equal(ui.document.body.classList.contains('sidebar-open'), false);
});

test('resizing to desktop removes the mobile inert state', () => {
  const ui = setup();
  ui.setMobile(false);
  ui.windowListeners.resize();

  assert.equal(ui.sidebar.inert, false);
  assert.equal(ui.sidebar['aria-hidden'], 'false');
});
