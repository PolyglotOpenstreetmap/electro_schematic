// lib/models/physical/channel_grouping.dart

/// A generic grouping of numbered channels within a specific terminal block,
/// used by the diagram painter to draw visual grouping boxes around related channels.
///
/// App code converts domain-specific groupings (e.g. TriacGrouping) to this
/// generic form before passing them to [PaginatedDiagramPainter].
class ChannelGrouping {
  /// Identifier for this grouping (e.g. bell group ID)
  final String groupId;

  /// ID of the terminal block this grouping belongs to
  final String blockId;

  /// 1-based channel indices that belong to this group
  final List<int> channelIndices;

  /// Optional display label shown on the grouping box
  final String? displayName;

  const ChannelGrouping({
    required this.groupId,
    required this.blockId,
    required this.channelIndices,
    this.displayName,
  });
}
