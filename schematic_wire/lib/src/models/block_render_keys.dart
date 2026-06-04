// lib/models/physical/block_render_keys.dart

/// Canonical render key names for terminal block dispatch.
///
/// These string constants are stored in [TerminalBlock.blockRenderKey] so the
/// diagram painter can dispatch to the correct drawing method without fragile
/// `block.id.contains(...)` string matching.
abstract final class BlockRenderKeys {
  static const String movotron = 'movotron';
  static const String movotronClockConn = 'movotronClockConn';
  static const String pkz = 'pkz';
  static const String triac = 'triac';
  static const String iii6sv = 'iii6sv';
  static const String striker = 'striker';
  static const String apolloRelayBoard = 'apolloRelayBoard';
  static const String apolloFetBoard = 'apolloFetBoard';
  static const String apolloClockConn = 'apolloClockConn';
  static const String sbsi = 'sbsi';
  static const String sbsiClockTower = 'sbsiClockTower';
  static const String sbsiStriker = 'sbsiStriker';
  static const String iv3mod3srl = 'iv3mod3srl';
}
