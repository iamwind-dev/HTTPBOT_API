import 'package:equatable/equatable.dart';

enum KeyValueItemType { text, file }

class KeyValueItem extends Equatable {
  const KeyValueItem({
    required this.key,
    required this.value,
    this.isEnabled = true,
    this.type = KeyValueItemType.text,
    this.contentType = '',
    this.description = '',
  });

  final String key;
  final String value;
  final bool isEnabled;
  final KeyValueItemType type;
  final String contentType;
  final String description;

  /// Returns true when the item key has meaningful user input.
  bool get hasKey => key.trim().isNotEmpty;

  /// Returns true when the item value or file path has meaningful user input.
  bool get hasValue => value.trim().isNotEmpty;

  /// Returns true when the item can participate in request resolution.
  bool get isComplete => isEnabled && hasKey && hasValue;

  /// Creates a new key-value item with any updated editor fields applied.
  KeyValueItem copyWith({
    String? key,
    String? value,
    bool? isEnabled,
    KeyValueItemType? type,
    String? contentType,
    String? description,
  }) => KeyValueItem(
    key: key ?? this.key,
    value: value ?? this.value,
    isEnabled: isEnabled ?? this.isEnabled,
    type: type ?? this.type,
    contentType: contentType ?? this.contentType,
    description: description ?? this.description,
  );

  @override
  List<Object> get props => [
    key,
    value,
    isEnabled,
    type,
    contentType,
    description,
  ];
}

typedef RequestKeyValue = KeyValueItem;
