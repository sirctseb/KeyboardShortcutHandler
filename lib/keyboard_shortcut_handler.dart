// Copyright 2006 The Closure Library Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS-IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/**
 * @fileoverview Generic keyboard shortcut handler.
 *
 * @author eae@google.com (Emil A Eklund)
 * @auther bestchris@gmail.com (Christopher Best)
 * @see ../demos/keyboardshortcuts.html
 */

library keyboard_shortcut_handler;

import 'dart:html';
import 'dart:async';

/**
 * Component for handling keyboard shortcuts. A shortcut is registered and bound
 * to a specific identifier. Once the shortcut is triggered an event is fired
 * with the identifier for the shortcut. This allows keyboard shortcuts to be
 * customized without modifying the code that listens for them.
*
 * Supports keyboard shortcuts triggered by a single key, a stroke stroke (key
 * plus at least one modifier) and a sequence of keys or strokes.
 */
class KeyboardShortcutHandler {

  /**
   * Registered keyboard shortcuts tree. Stored as a map with the keyCode and
   * modifier(s) as the key and either a list of further strokes or the shortcut
   * task identifier as the value.
   * @type {Object}
   * @see #makeKey_
   * @private
   */
  Map<int, Object> _shortcuts = new Map<int, Object>();

  /**
   * List of the last sequence of strokes. Object contains time last key was
   * pressed and an array of strokes, represented by numeric value.
   * @type {Object}
   * @private
   */
  var _lastKeys = {'strokes': [], 'time': 0};

  /**
   * List of numeric key codes for keys that are safe to always regarded as
   * shortcuts, even if entered in a textarea or input field.
   * @type {Object}
   * @private
   */
  var _globalKeys = new Set.from(_DEFAULT_GLOBAL_KEYS);

  /**
   * List of input types that should only accept ENTER as a shortcut.
   * @type {Object}
   * @private
   */
  var _textInputs = new Set.from(_DEFAULT_TEXT_INPUTS);

  /**
   * Whether to always prevent the default action when a shortcut event is
   * fired. If false, the default action is prevented only if preventDefault is
   * called on  either of the corresponding SHORTCUT_TRIGGERED or SHORTCUT_PREFIX
   * events. If true, the default action is prevented whenever a shortcut event
   * is fired. The default value is true.
   */
  bool alwaysPreventDefault = true;

  /**
   * Whether to always stop propagation for the event when fired. If false,
   * the propagation is stopped only if stopPropagation is called on either of the
   * corresponding SHORT_CUT_TRIGGERED or SHORTCUT_PREFIX events. If true, the
   * event is prevented from propagating beyond its target whenever it is fired.
   * The default value is false.
   */
  bool alwaysStopPropagation = false;

  /**
   * Whether to treat all shortcuts (including modifier shortcuts) as if the
   * keys had been passed to the setGlobalKeys function.
   */
  bool allShortcutsAreGlobal = false;

  /**
   * Whether to treat shortcuts with modifiers as if the keys had been
   * passed to the setGlobalKeys function.  Ignored if you have called
   * setAllShortcutsAreGlobal(true).  Applies only to form elements (not
   * content-editable).
   */
  bool modifierShortcutsAreGlobal = true;

  /** @param {goog.events.EventTarget|EventTarget} keyTarget Event target that the
   *     key event listener is attached to, typically the applications root
   *     container.
   * @constructor
   * @extends {goog.events.EventTarget}
   */
  KeyboardShortcutHandler(keyTarget) {
    initializeKeyListener(keyTarget);
  }

  /**
   * Maximum allowed delay, in milliseconds, allowed between the first and second
   * key in a key sequence.
   * @type {number}
   */
  static num MAX_KEY_SEQUENCE_DELAY = 1500; // 1.5 sec

  /**
   * Key names for common characters.
  *
   * This list is not localized and therefore some of the key codes are not
   * correct for non-US keyboard layouts.
  *
   * @see goog.events.KeyCodes
   * @enum {string}
   */
  static Map<int, String> KeyNames = _makeKeyNames();
  static Map<int, String> _makeKeyNames() {
    Map<int, String> ret = new Map<int, String>();
    _KeyNamesString.forEach((key, val) => ret[int.parse(key)] = val);
    return ret;
  }

  static Map _KeyNamesString = {
    '8': 'backspace',
    '9': 'tab',
    '13': 'enter',
    '16': 'shift',
    '17': 'ctrl',
    '18': 'alt',
    '19': 'pause',
    '20': 'caps-lock',
    '27': 'esc',
    '32': 'space',
    '33': 'pg-up',
    '34': 'pg-down',
    '35': 'end',
    '36': 'home',
    '37': 'left',
    '38': 'up',
    '39': 'right',
    '40': 'down',
    '45': 'insert',
    '46': 'delete',
    '48': '0',
    '49': '1',
    '50': '2',
    '51': '3',
    '52': '4',
    '53': '5',
    '54': '6',
    '55': '7',
    '56': '8',
    '57': '9',
    '59': 'semicolon',
    '61': 'equals',
    '65': 'a',
    '66': 'b',
    '67': 'c',
    '68': 'd',
    '69': 'e',
    '70': 'f',
    '71': 'g',
    '72': 'h',
    '73': 'i',
    '74': 'j',
    '75': 'k',
    '76': 'l',
    '77': 'm',
    '78': 'n',
    '79': 'o',
    '80': 'p',
    '81': 'q',
    '82': 'r',
    '83': 's',
    '84': 't',
    '85': 'u',
    '86': 'v',
    '87': 'w',
    '88': 'x',
    '89': 'y',
    '90': 'z',
    '93': 'context',
    '96': 'num-0',
    '97': 'num-1',
    '98': 'num-2',
    '99': 'num-3',
    '100': 'num-4',
    '101': 'num-5',
    '102': 'num-6',
    '103': 'num-7',
    '104': 'num-8',
    '105': 'num-9',
    '106': 'num-multiply',
    '107': 'num-plus',
    '109': 'num-minus',
    '110': 'num-period',
    '111': 'num-division',
    '112': 'f1',
    '113': 'f2',
    '114': 'f3',
    '115': 'f4',
    '116': 'f5',
    '117': 'f6',
    '118': 'f7',
    '119': 'f8',
    '120': 'f9',
    '121': 'f10',
    '122': 'f11',
    '123': 'f12',
    '186': 'semicolon',
    '187': 'equals',
    '189': 'dash',
    '188': ',',
    '190': '.',
    '191': '/',
    '192': '`',
    '219': 'open-square-bracket',
    '220': '\\',
    '221': 'close-square-bracket',
    '222': 'single-quote',
    '224': 'win'
  };

  /**
   * Key codes for common characters.
  *
   * This list is not localized and therefore some of the key codes are not
   * correct for non US keyboard layouts. See comments below.
  *
   * @enum {number}
   */
  static final KeyCodes = {
    'WIN_KEY_FF_LINUX': 0,
    'MAC_ENTER': 3,
    'BACKSPACE': 8,
    'TAB': 9,
    'NUM_CENTER': 12, // NUMLOCK on FF/Safari Mac
    'ENTER': 13,
    'SHIFT': 16,
    'CTRL': 17,
    'ALT': 18,
    'PAUSE': 19,
    'CAPS_LOCK': 20,
    'ESC': 27,
    'SPACE': 32,
    'PAGE_UP': 33, // also NUM_NORTH_EAST
    'PAGE_DOWN': 34, // also NUM_SOUTH_EAST
    'END': 35, // also NUM_SOUTH_WEST
    'HOME': 36, // also NUM_NORTH_WEST
    'LEFT': 37, // also NUM_WEST
    'UP': 38, // also NUM_NORTH
    'RIGHT': 39, // also NUM_EAST
    'DOWN': 40, // also NUM_SOUTH
    'PRINT_SCREEN': 44,
    'INSERT': 45, // also NUM_INSERT
    'DELETE': 46, // also NUM_DELETE
    'ZERO': 48,
    'ONE': 49,
    'TWO': 50,
    'THREE': 51,
    'FOUR': 52,
    'FIVE': 53,
    'SIX': 54,
    'SEVEN': 55,
    'EIGHT': 56,
    'NINE': 57,
    'FF_SEMICOLON':
        59, // Firefox (Gecko) fires this for semicolon instead of 186
    'FF_EQUALS': 61, // Firefox (Gecko) fires this for equals instead of 187
    'QUESTION_MARK': 63, // needs localization
    'A': 65,
    'B': 66,
    'C': 67,
    'D': 68,
    'E': 69,
    'F': 70,
    'G': 71,
    'H': 72,
    'I': 73,
    'J': 74,
    'K': 75,
    'L': 76,
    'M': 77,
    'N': 78,
    'O': 79,
    'P': 80,
    'Q': 81,
    'R': 82,
    'S': 83,
    'T': 84,
    'U': 85,
    'V': 86,
    'W': 87,
    'X': 88,
    'Y': 89,
    'Z': 90,
    'META': 91, // WIN_KEY_LEFT
    'WIN_KEY_RIGHT': 92,
    'CONTEXT_MENU': 93,
    'NUM_ZERO': 96,
    'NUM_ONE': 97,
    'NUM_TWO': 98,
    'NUM_THREE': 99,
    'NUM_FOUR': 100,
    'NUM_FIVE': 101,
    'NUM_SIX': 102,
    'NUM_SEVEN': 103,
    'NUM_EIGHT': 104,
    'NUM_NINE': 105,
    'NUM_MULTIPLY': 106,
    'NUM_PLUS': 107,
    'NUM_MINUS': 109,
    'NUM_PERIOD': 110,
    'NUM_DIVISION': 111,
    'F1': 112,
    'F2': 113,
    'F3': 114,
    'F4': 115,
    'F5': 116,
    'F6': 117,
    'F7': 118,
    'F8': 119,
    'F9': 120,
    'F10': 121,
    'F11': 122,
    'F12': 123,
    'NUMLOCK': 144,
    'SCROLL_LOCK': 145,

    // OS-specific media keys like volume controls and browser controls.
    'FIRST_MEDIA_KEY': 166,
    'LAST_MEDIA_KEY': 183,
    'SEMICOLON': 186, // needs localization
    'DASH': 189, // needs localization
    'EQUALS': 187, // needs localization
    'COMMA': 188, // needs localization
    'PERIOD': 190, // needs localization
    'SLASH': 191, // needs localization
    'APOSTROPHE': 192, // needs localization
    'TILDE': 192, // needs localization
    'SINGLE_QUOTE': 222, // needs localization
    'OPEN_SQUARE_BRACKET': 219, // needs localization
    'BACKSLASH': 220, // needs localization
    'CLOSE_SQUARE_BRACKET': 221, // needs localization
    'WIN_KEY': 224,
    'MAC_FF_META':
        224, // Firefox (Gecko) fires this for the meta key instead of 91
    'WIN_IME': 229,

    // We've seen users whose machines fire this keycode at regular one
    // second intervals. The common thread among these users is that
    // they're all using Dell Inspiron laptops, so we suspect that this
    // indicates a hardware/bios problem.
    //'http'://en.community.dell.com/support-forums/laptop/f/3518/p/19285957/19523128.aspx
    'PHANTOM': 255
  };
  static int normalizeGeckoKeyCode(int keyCode) {
    if (keyCode == KeyCodes['FF_EQUALS']) {
      return KeyCodes['EQUALS'];
    } else if (keyCode == KeyCodes['FF_SEMICOLON']) {
      return KeyCodes['SEMICOLON'];
    } else if (keyCode == KeyCodes['FF_DASH']) {
      return KeyCodes['DASH'];
    } else if (keyCode == KeyCodes['MAC_FF_META']) {
      return KeyCodes['META'];
    } else if (keyCode == KeyCodes['WIN_KEY_FF_LINUX']) {
      return KeyCodes['WIN_KEY'];
    }
    return keyCode;
  }

  /**
   * Bit values for modifier keys.
   * @enum {number}
   */
  static var _Modifiers = {
    'NONE': 0,
    'SHIFT': 1,
    'CTRL': 2,
    'ALT': 4,
    'META': 8
  };

  /**
   * Keys marked as global by default.
   * @type {Array.<goog.events.KeyCodes>}
   * @private
   */
  static var _DEFAULT_GLOBAL_KEYS = [
    KeyCodes['ESC'],
    KeyCodes['F1'],
    KeyCodes['F2'],
    KeyCodes['F3'],
    KeyCodes['F4'],
    KeyCodes['F5'],
    KeyCodes['F6'],
    KeyCodes['F7'],
    KeyCodes['F8'],
    KeyCodes['F9'],
    KeyCodes['F10'],
    KeyCodes['F11'],
    KeyCodes['F12'],
    KeyCodes['PAUSE']
  ];

  /** Map from printable characters that are typed when shift is held
   * to the KeyName that is typed without shift.
   */
  static final _ShiftKeys = _makeShiftKeys();
  static Map _makeShiftKeys() {
    var ret = {};
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').forEach((upper) {
      ret[upper] = upper.toLowerCase();
    });
    return ret
      ..addAll({
        '~': '`',
        '!': '1',
        '@': '2',
        '#': '3',
        r'$': '4',
        '%': '5',
        '^': '6',
        '&': '7',
        '*': '8',
        '(': '9',
        ')': '0',
        '_': 'dash',
        '+': 'equals',
        '{': 'open-square-bracket',
        '}': 'close-square-bracket',
        '|': r'\',
        ':': 'semicolon',
        '\"': 'single-quote',
        '<': ',',
        '>': '.',
        '?': '/'
      });
  }

  /**
   * Text input types to allow only ENTER shortcuts.
   * Web Forms 2.0 for HTML5: Section 4.10.7 from 29 May 2012.
   * @type {Array.<string>}
   * @private
   */
  static var _DEFAULT_TEXT_INPUTS = [
    'color',
    'date',
    'datetime',
    'datetime-local',
    'email',
    'month',
    'number',
    'password',
    'search',
    'tel',
    'text',
    'time',
    'url',
    'week'
  ];

  /**
   * Cache for name to key code lookup.
   * @type {Object}
   * @private
   */
  static var _nameToKeyCodeCache;

  /**
   * Target on which to listen for key events.
   * @type {goog.events.EventTarget|EventTarget}
   * @private
   */
  var _keyTarget;

  /**
   * Due to a bug in the way that Gecko v1.8 on Mac handles
   * cut/copy/paste key events using the meta key, it is necessary to
   * fake the keydown for the action key (C,V,X) by capturing it on keyup.
   * Because users will often release the meta key a slight moment
   * before they release the action key, we need this variable that will
   * store whether the meta key has been released recently.
   * It will be cleared after a short delay in the key handling logic.
   * @type {boolean}
   * @private
   */
  bool _metaKeyRecentlyReleased;

  /**
   * Whether a key event is a printable-key event. Windows uses ctrl+alt
   * (alt-graph) keys to type characters on European keyboards. For such keys, we
   * cannot identify whether these keys are used for typing characters when
   * receiving keydown events. Therefore, we set this flag when we receive their
   * respective keypress events and fire shortcut events only when we do not
   * receive them.
   * @type {boolean}
   * @private
   */
  bool _isPrintableKey;

  /**
   * Static method for getting the key code for a given key.
   * @param {string} name Name of key.
   * @return {number} The key code.
   */
  static int getKeyCode(String name) {
    // Build reverse lookup object the first time this method is called.
    if (_nameToKeyCodeCache == null) {
      var map = {};
      for (var key in KeyNames.keys) {
        map[KeyNames[key]] = key;
      }
      _nameToKeyCodeCache = map;
    }

    // Check if key is in cache.
    return _nameToKeyCodeCache[name];
  }

  /**
   * Registers a keyboard shortcut.
   * @param {string} identifier Identifier for the task performed by the keyboard
   *                 combination. Multiple shortcuts can be provided for the same
   *                 task by specifying the same identifier.
   * @param {...(number|string|Array.<number>)} var_args See below.
   *
   * param {number} keyCode Numeric code for key
   * param {number=} opt_modifiers Bitmap indicating required modifier keys.
   *                goog.ui.KeyboardShortcutHandler.Modifiers.SHIFT, CONTROL,
   *                ALT, or META.
   *
   * The last two parameters can be repeated any number of times to create a
   * shortcut using a sequence of strokes. Instead of varagrs the second parameter
   * could also be an array where each element would be ragarded as a parameter.
   *
   * A string representation of the shortcut can be supplied instead of the last
   * two parameters. In that case the method only takes two arguments, the
   * identifier and the string.
   *
   * Examples:
   *   g               registerShortcut(str, G_KEYCODE)
   *   Ctrl+g          registerShortcut(str, G_KEYCODE, CTRL)
   *   Ctrl+Shift+g    registerShortcut(str, G_KEYCODE, CTRL | SHIFT)
   *   Ctrl+g a        registerShortcut(str, G_KEYCODE, CTRL, A_KEYCODE)
   *   Ctrl+g Shift+a  registerShortcut(str, G_KEYCODE, CTRL, A_KEYCODE, SHIFT)
   *   g a             registerShortcut(str, G_KEYCODE, NONE, A_KEYCODE)
   *
   * Examples using string representation for shortcuts:
   *   g               registerShortcut(str, 'g')
   *   Ctrl+g          registerShortcut(str, 'ctrl+g')
   *   Ctrl+Shift+g    registerShortcut(str, 'ctrl+shift+g')
   *   Ctrl+g a        registerShortcut(str, 'ctrl+g a')
   *   Ctrl+g Shift+a  registerShortcut(str, 'ctrl+g shift+a')
   *   g a             registerShortcut(str, 'g a').
   */
  void registerShortcut(String identifier, arg) {
    // Add shortcut to shortcuts_ tree
    _setShortcut(_shortcuts, _interpretStrokes(arg), identifier);
  }

  /**
   * Unregisters a keyboard shortcut by keyCode and modifiers or string
   * representation of sequence.
   *
   * param {number} keyCode Numeric code for key
   * param {number=} opt_modifiers Bitmap indicating required modifier keys.
   *                 goog.ui.KeyboardShortcutHandler.Modifiers.SHIFT, CONTROL,
   *                 ALT, or META.
   *
   * The two parameters can be repeated any number of times to create a shortcut
   * using a sequence of strokes.
   *
   * A string representation of the shortcut can be supplied instead see
   * {@link #registerShortcut} for syntax. In that case the method only takes one
   * argument.
   *
   * @param {...(number|string|Array.<number>)} var_args String representation, or
   *     array or list of alternating key codes and modifiers.
   */
  void unregisterShortcut(arg) {
    // Remove shortcut from tree
    _setShortcut(_shortcuts, _interpretStrokes(arg), null);
  }

  /**
   * Verifies if a particular keyboard shortcut is registered already. It has
   * the same interface as the unregistering of shortcuts.
   *
   * param {number} keyCode Numeric code for key
   * param {number=} opt_modifiers Bitmap indicating required modifier keys.
   *                 goog.ui.KeyboardShortcutHandler.Modifiers.SHIFT, CONTROL,
   *                 ALT, or META.
   *
   * The two parameters can be repeated any number of times to create a shortcut
   * using a sequence of strokes.
   *
   * A string representation of the shortcut can be supplied instead see
   * {@link #registerShortcut} for syntax. In that case the method only takes one
   * argument.
   *
   * @param {...(number|string|Array.<number>)} var_args String representation, or
   *     array or list of alternating key codes and modifiers.
   * @return {boolean} Whether the specified keyboard shortcut is registered.
   */
  bool isShortcutRegistered(arg) {
    return _checkShortcut(_interpretStrokes(arg));
  }

  /**
   * Parses the variable arguments for registerShortcut and unregisterShortcut.
   * @param {number} initialIndex The first index of "args" to treat as
   *     variable arguments.
   * @param {Object} args The "arguments" array passed
   *     to registerShortcut or unregisterShortcut.  Please see the comments in
   *     registerShortcut for list of allowed forms.
   * @return {Array.<Object>} The sequence of objects containing the
   *     keyCode and modifiers of each key in sequence.
   * @private
   */
  List _interpretStrokes(arg) {
    List strokes;

    // Build strokes array from string.
    if (arg is String) {
      strokes = parseStringShortcut(arg);

      // Build strokes array from arguments list or from array.
    } else {
      var strokesArgs = arg;
      if (arg is List) {
        strokesArgs = arg;
      }

      strokes = [];
      for (int i = 0; i < strokesArgs.length; i += 2) {
        strokes
            .add({'keyCode': strokesArgs[i], 'modifiers': strokesArgs[i + 1]});
      }
    }

    return strokes;
  }

  /**
   * Unregisters all keyboard shortcuts.
   */
  void unregisterAll() {
    _shortcuts = {};
  }

  /**
   * Sets the global keys; keys that are safe to always regarded as shortcuts,
   * even if entered in a textarea or input field.
   * @param {Array.<number>} keys List of keys.
   */
  void setGlobalKeys(List keys) {
    _globalKeys = new Set.from(keys);
  }

  /**
   * @return {Array.<string>} The global keys, i.e. keys that are safe to always
   *     regard as shortcuts, even if entered in a textarea or input field.
   */
  List<String> getGlobalKeys() {
    return _globalKeys.toList();
  }

  /** @override */
  void disposeInternal() {
    unregisterAll();
    clearKeyListener();
  }

  /**
   * Builds stroke array from string representation of shortcut.
   * @param {string} s String representation of shortcut.
   * @return {Array.<Object>} The stroke array.
   */
  List parseStringShortcut(String s) {
    // Normalize whitespace
    s = s
        .replaceAll(new RegExp(r'[ +]*\+[ +]*'), '+')
        .replaceAll(new RegExp('[ ]+'), ' ');

    // Build strokes array from string, space separates strokes, plus separates
    // individual keys.
    var groups = s.split(' ');
    var strokes = [];
    var group;
    // TODO I think for condition ends on empty string?
    for (int i = 0; i < groups.length; i++) {
      group = groups[i];

      var keys = group.split('+');

      // if the key is a shift character,
      // add a shift modifier
      if (_ShiftKeys.keys.contains(keys.last)) {
        // add shift
        keys.insert(0, 'shift');
        // change the character to the unshifted name
        keys.add(_ShiftKeys[keys.removeLast()]);
      }

      var keyCode, modifiers = _Modifiers['NONE'];
      for (var key, j = 0; (key = keys[j]) != ''; j++) {
        switch (key) {
          case 'shift':
            modifiers |= _Modifiers['SHIFT'];
            continue;
          case 'ctrl':
            modifiers |= _Modifiers['CTRL'];
            continue;
          case 'alt':
            modifiers |= _Modifiers['ALT'];
            continue;
          case 'meta':
            modifiers |= _Modifiers['META'];
            continue;
        }
        keyCode = getKeyCode(key);
        break;
      }
      strokes.add({'keyCode': keyCode, 'modifiers': modifiers});
    }
    return strokes;
  }

  static bool get OPERA {
    return window.navigator.userAgent.contains('Opera');
  }

  static bool get WEBKIT {
    return !OPERA && window.navigator.userAgent.contains('WebKit');
  }

  static bool get GECKO {
    return !OPERA && !WEBKIT && window.navigator.product == 'Gecko';
  }

  static bool get MAC {
    return window.navigator.platform.contains('Mac');
  }

  static bool get WINDOWS {
    return window.navigator.platform.contains('Win');
  }

  StreamSubscription _keyDownSubscription;
  StreamSubscription _keyUpSubscription;
  StreamSubscription _keyPressSubscription;

  StreamController<KeyboardShortcutEvent> _shortcutStreamController =
      new StreamController<KeyboardShortcutEvent>();
  /**
   * A stream that receives [KeyboardShortcutEvents] that are triggered by shortcuts
   * registered on this [KeyboardShortcutHandler]
   */
  Stream<KeyboardShortcutEvent> get onShortcut =>
      _shortcutStreamController.stream;

  /**
   * Adds a key event listener that triggers {@link #handleKeyDown_} when keys
   * are pressed.
   * @param {goog.events.EventTarget|EventTarget} keyTarget Event target that the
   *     event listener should be attached to.
   * @protected
   */
  void initializeKeyListener(keyTarget) {
    _keyTarget = keyTarget;

    _keyDownSubscription = keyTarget.onKeyDown.listen(_handleKeyDown);
    // Firefox 2 on mac does not fire a keydown event in conjunction with a meta
    // key if the action involves cutting/copying/pasting text.
    // In this case we capture the keyup (which is fired) and fake as
    // if the user had pressed the key to begin with.
    // TODO test for version 1.8 or higher
    //if (MAC && GECKO && goog.userAgent.isVersionOrHigher('1.8')) {
    if (MAC && GECKO) {
      _keyUpSubscription = _keyTarget.onKeyUp.listen(_handleMacGeckoKeyUp);
    }

    // Windows uses ctrl+alt keys (a.k.a. alt-graph keys) for typing characters
    // on European keyboards (e.g. ctrl+alt+e for an an euro sign.) Unfortunately,
    // Windows browsers except Firefox does not have any methods except listening
    // keypress and keyup events to identify if ctrl+alt keys are really used for
    // inputting characters. Therefore, we listen to these events and prevent
    // firing shortcut-key events if ctrl+alt keys are used for typing characters.
    if (WINDOWS && !GECKO) {
      _keyPressSubscription =
          _keyTarget.onKeyPress.listen(_handleWindowsKeyPress);
      _keyUpSubscription = _keyTarget.onKeyUp.listen(_handleWindowsKeyUp);
    }
  }

  /**
   * Handler for when a keyup event is fired in Mac FF2 (Gecko 1.8).
   * @param {goog.events.BrowserEvent} e The key event.
   * @private
   */
  void _handleMacGeckoKeyUp(KeyboardEvent e) {
    // Due to a bug in the way that Gecko v1.8 on Mac handles
    // cut/copy/paste key events using the meta key, it is necessary to
    // fake the keydown for the action keys (C,V,X) by capturing it on keyup.
    // This is because the keydown events themselves are not fired by the
    // browser in this case.
    // Because users will often release the meta key a slight moment
    // before they release the action key, we need to store whether the
    // meta key has been released recently to avoid "flaky" cutting/pasting
    // behavior.
    if (e.keyCode == KeyCodes['MAC_FF_META']) {
      _metaKeyRecentlyReleased = true;
      new Timer(new Duration(milliseconds: 400), () {
        this._metaKeyRecentlyReleased = false;
      });
      return;
    }

    var metaKey = e.metaKey || this._metaKeyRecentlyReleased;
    if ((e.keyCode == KeyCodes['C'] ||
            e.keyCode == KeyCodes['X'] ||
            e.keyCode == KeyCodes['V']) &&
        metaKey) {
      // TODO can't set metaKey. is final on event class
      //e.metaKey = metaKey;
      _handleKeyDown(e);
    }
  }

  /**
   * Returns whether this event is possibly used for typing a printable character.
   * Windows uses ctrl+alt (a.k.a. alt-graph) keys for typing characters on
   * European keyboards. Since only Firefox provides a method that can identify
   * whether ctrl+alt keys are used for typing characters, we need to check
   * whether Windows sends a keypress event to prevent firing shortcut event if
   * this event is used for typing characters.
   * @param {goog.events.BrowserEvent} e The key event.
   * @return {boolean} Whether this event is a possible printable-key event.
   * @private
   */
  bool _isPossiblePrintableKey(KeyboardEvent e) {
    return WINDOWS && !GECKO && e.ctrlKey && e.altKey && !e.shiftKey;
  }

  /**
   * Handler for when a keypress event is fired on Windows.
   * @param {goog.events.BrowserEvent} e The key event.
   * @private
   */
  void _handleWindowsKeyPress(KeyboardEvent e) {
    // When this keypress event consists of a printable character, set the flag to
    // prevent firing shortcut key events when we receive the succeeding keyup
    // event. We accept all Unicode characters except control ones since this
    // keyCode may be a non-ASCII character.
    if (e.keyCode > 0x20 && _isPossiblePrintableKey(e)) {
      _isPrintableKey = true;
    }
  }

  /**
   * Handler for when a keyup event is fired on Windows.
   * @param {goog.events.BrowserEvent} e The key event.
   * @private
   */
  void _handleWindowsKeyUp(KeyboardEvent e) {
    // For possible printable-key events, try firing a shortcut-key event only
    // when this event is not used for typing a character.
    if (!((_isPrintableKey == null) ? false : _isPrintableKey) &&
        _isPossiblePrintableKey(e)) {
      _handleKeyDown(e);
    }
  }

  /**
   * Removes the listener that was added by link {@link #initializeKeyListener}.
   * @protected
   */
  void clearKeyListener() {
    _keyDownSubscription.cancel();
    // TODO test for 1.8 or higher
    //if (MAC && GECKO && goog.userAgent.isVersionOrHigher('1.8')) {
    if (MAC && GECKO) {
      _keyUpSubscription.cancel();
    }
    if (WINDOWS && !GECKO) {
      _keyPressSubscription.cancel();
      _keyUpSubscription.cancel();
    }
    _keyTarget = null;
  }

  /**
   * Adds or removes a stroke node to/from the given parent node.
   * @param {Object} parent Parent node to add/remove stroke to/from.
   * @param {Array.<Object>} strokes Array of strokes for shortcut.
   * @param {?string} identifier Identifier for the task performed by shortcut or
   *     null to clear.
   * @private
   */
  void _setShortcut(parent, List strokes, String identifier) {
    var stroke = strokes.removeAt(0);
    var key = _makeKey(stroke['keyCode'], stroke['modifiers']);
    var node = parent[key];
    if (node != null &&
        identifier != null &&
        (strokes.length == 0 || node is String)) {
      throw 'Keyboard shortcut conflicts with existing shortcut';
    }

    if (strokes.length > 0) {
      if (node == null) {
        node = parent[key] = new Map<int, Object>();
      }
      _setShortcut(node, strokes, identifier);
    } else {
      parent[key] = identifier;
    }
  }

  /**
   * Returns shortcut for a specific set of strokes.
   * @param {Array.<number>} strokes Strokes array.
   * @param {number=} opt_index Index in array to start with.
   * @param {Object=} opt_list List to search for shortcut in.
   * @return {string|Object} The shortcut.
   * @private
   */
  _getShortcut(List strokes, [int opt_index, opt_list]) {
    var list = opt_list != null ? opt_list : _shortcuts;
    int index = opt_index != null ? opt_index : 0;
    var stroke = strokes[index];
    var node = list[stroke];

    if (node != null && !(node is String) && strokes.length - index > 1) {
      return _getShortcut(strokes, index + 1, node);
    }

    return node;
  }

  /**
   * Checks if a particular keyboard shortcut is registered.
   * @param {Array.<Object>} strokes Strokes array.
   * @return {boolean} True iff the keyboard is registred.
   * @private
   */
  bool _checkShortcut(List strokes) {
    var node = _shortcuts;
    while (strokes.length > 0 && node != null) {
      var stroke = strokes.removeAt(0);
      var key = _makeKey(stroke.keyCode, stroke.modifiers);
      node = node[key];
      if (node is String) {
        return true;
      }
    }
    return false;
  }

  /**
   * Constructs key from key code and modifiers.
   *
   * The lower 8 bits are used for the key code, the following 3 for modifiers and
   * the remaining bits are unused.
   *
   * @param {number} keyCode Numeric key code.
   * @param {number} modifiers Required modifiers.
   * @return {number} The key.
   * @private
   */
  static int _makeKey(int keyCode, int modifiers) {
    // Make sure key code is just 8 bits and OR it with the modifiers left shifted
    // 8 bits.
    return (keyCode & 255) | (modifiers << 8);
  }

  /**
   * Keypress handler.
   * @param {goog.events.BrowserEvent} event Keypress event.
   * @private
   */
  void _handleKeyDown(KeyboardEvent event) {
    if (!_isValidShortcut(event)) {
      return;
    }
    // For possible printable-key events, we cannot identify whether the events
    // are used for typing characters until we receive respective keyup events.
    // Therefore, we handle this event when we receive a succeeding keyup event
    // to verify this event is not used for typing characters.
    // TODO check case for event.type
    if (event.type == 'keydown' && _isPossiblePrintableKey(event)) {
      _isPrintableKey = false;
      return;
    }

    var keyCode = GECKO ? normalizeGeckoKeyCode(event.keyCode) : event.keyCode;

    var modifiers = (event.shiftKey ? _Modifiers['SHIFT'] : 0) |
        (event.ctrlKey ? _Modifiers['CTRL'] : 0) |
        (event.altKey ? _Modifiers['ALT'] : 0) |
        (event.metaKey ? _Modifiers['META'] : 0);
    var stroke = _makeKey(keyCode, modifiers);

    // Check if any previous strokes where entered within the acceptable time
    // period.
    var node, shortcut;
    var now = new DateTime.now();
    if (_lastKeys['strokes'].length > 0 &&
        now.difference(_lastKeys['time']).inMilliseconds <=
            MAX_KEY_SEQUENCE_DELAY) {
      node = _getShortcut(_lastKeys['strokes']);
    } else {
      _lastKeys['strokes'].clear();
    }

    // Check if this stroke triggers a shortcut, either on its own or combined
    // with previous strokes.
    node = node != null ? node[stroke] : _shortcuts[stroke];
    if (node == null) {
      node = _shortcuts[stroke];
      _lastKeys['strokes'] = [];
    }
    // Check if stroke triggers a node.
    if (node != null && node is String) {
      shortcut = node;
    }

    // Entered stroke(s) are a part of a sequence, store stroke and record
    // time to allow the following stroke(s) to trigger the shortcut.
    else if (node != null) {
      _lastKeys['strokes'].add(stroke);
      _lastKeys['time'] = now;
      // Prevent default action so find-as-you-type doesn't steal keyboard focus.
      if (GECKO) {
        event.preventDefault();
      }
    }

    // No strokes for sequence, clear stored strokes.
    else {
      _lastKeys['strokes'].clear();
    }

    // Dispatch keyboard shortcut event if a shortcut was triggered. In addition
    // to the generic keyboard shortcut event a more specifc fine grained one,
    // specific for the shortcut identifier, is fired.
    if (shortcut != null && shortcut != '') {
      if (alwaysPreventDefault) {
        event.preventDefault();
      }

      if (alwaysStopPropagation) {
        event.stopPropagation();
      }

      // TODO separate event for triggered?
      // Dispatch SHORTCUT_TRIGGERED event
      //var triggerEvent = new KeyboardShortcutEvent(
      //    types.SHORTCUT_TRIGGERED, shortcut, target);
      //var retVal = this.dispatchEvent(triggerEvent);

      // put event on stream
      _shortcutStreamController.add(new KeyboardShortcutEvent(shortcut, event));

      // Clear stored strokes
      _lastKeys['strokes'].clear();
    }
  }

  /**
   * Checks if a given keypress event may be treated as a shortcut.
   * @param {goog.events.BrowserEvent} event Keypress event.
   * @return {boolean} Whether to attempt to process the event as a shortcut.
   * @private
   */
  bool _isValidShortcut(KeyboardEvent event) {
    var keyCode = event.keyCode;

    // Ignore Ctrl, Shift and ALT
    if (keyCode == KeyCodes['SHIFT'] ||
        keyCode == KeyCodes['CTRL'] ||
        keyCode == KeyCodes['ALT']) {
      return false;
    }
    var el = /** @type {Element} */ (event.target);
    bool isFormElement = el.tagName == 'TEXTAREA' ||
        el.tagName == 'INPUT' ||
        el.tagName == 'BUTTON' ||
        el.tagName == 'SELECT';

    //bool isContentEditable = !isFormElement && (el.isContentEditable ||
    //    (document != null && document.designMode == 'on'));
    // TODO dart doesn't have designMode
    bool isContentEditable = !isFormElement && el.isContentEditable;

    if (!isFormElement && !isContentEditable) {
      return true;
    }
    // Always allow keys registered as global to be used (typically Esc, the
    // F-keys and other keys that are not typically used to manipulate text).
    if (_globalKeys.contains(keyCode) || allShortcutsAreGlobal) {
      return true;
    }
    if (isContentEditable) {
      // For events originating from an element in editing mode we only let
      // global key codes through.
      return false;
    }
    // Event target is one of (TEXTAREA, INPUT, BUTTON, SELECT).
    // Allow modifier shortcuts, unless we shouldn't.
    if (modifierShortcutsAreGlobal &&
        (event.altKey || event.ctrlKey || event.metaKey)) {
      return true;
    }
    // Allow ENTER to be used as shortcut for text inputs.
    if (el.tagName == 'INPUT' && _textInputs.contains(el.type)) {
      return keyCode == KeyCodes['ENTER'];
    }
    // Checkboxes, radiobuttons and buttons. Allow all but SPACE as shortcut.
    if (el.tagName == 'INPUT' || el.tagName == 'BUTTON') {
      return keyCode != KeyCodes['SPACE'];
    }
    // Don't allow any additional shortcut keys for textareas or selects.
    return false;
  }
}

/**
 * Object representing a keyboard shortcut event.
 * @param {string} type Event type.
 * @param {string} identifier Task identifier for the triggered shortcut.
 * @param {Node|goog.events.EventTarget} target Target the original key press
 *     event originated from.
 * @extends {goog.events.Event}
 * @constructor
 */
class KeyboardShortcutEvent {
  /**
   * Task identifier for the triggered shortcut
   * @type {string}
   */
  final String identifier;

  /// The final [KeyboardEvent] that triggered the shortcut
  final KeyboardEvent event;
  // TODO target?
  KeyboardShortcutEvent(String this.identifier, KeyboardEvent this.event);
}
