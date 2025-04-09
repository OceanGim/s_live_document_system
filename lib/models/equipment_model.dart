/// 장비 모델 클래스
/// 대관 시 대여 가능한 장비 정보 표현
class EquipmentModel {
  /// 기본 생성자
  EquipmentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.totalQuantity,
    required this.createdAt,
    this.description,
    this.imagePath,
    this.imageUrl,
    this.availableQuantity,
    this.serialNumber,
    this.manufacturer,
    this.purchaseDate,
    this.lastMaintenanceDate,
    this.status = 'available',
    this.rentFee = 0,
    this.depositFee = 0,
  });

  /// JSON 데이터로부터 EquipmentModel 인스턴스 생성
  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      totalQuantity: json['total_quantity'],
      availableQuantity: json['available_quantity'],
      description: json['description'],
      imagePath: json['image_path'],
      imageUrl: json['image_url'],
      serialNumber: json['serial_number'],
      manufacturer: json['manufacturer'],
      purchaseDate:
          json['purchase_date'] != null
              ? DateTime.parse(json['purchase_date'])
              : null,
      lastMaintenanceDate:
          json['last_maintenance_date'] != null
              ? DateTime.parse(json['last_maintenance_date'])
              : null,
      status: json['status'] ?? 'available',
      rentFee: json['rent_fee'] ?? 0,
      depositFee: json['deposit_fee'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// EquipmentModel 인스턴스를 JSON 데이터로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'total_quantity': totalQuantity,
      'available_quantity': availableQuantity,
      'description': description,
      'image_path': imagePath,
      'image_url': imageUrl,
      'serial_number': serialNumber,
      'manufacturer': manufacturer,
      'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
      'last_maintenance_date':
          lastMaintenanceDate?.toIso8601String().split('T')[0],
      'status': status,
      'rent_fee': rentFee,
      'deposit_fee': depositFee,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 장비 ID (UUID)
  final String id;

  /// 장비명
  final String name;

  /// 카테고리 (ex: 카메라, 조명, 음향 등)
  final String category;

  /// 총 보유 수량
  final int totalQuantity;

  /// 대여 가능 수량
  final int? availableQuantity;

  /// 장비 설명
  final String? description;

  /// 장비 이미지 경로
  final String? imagePath;

  /// 장비 이미지 URL
  final String? imageUrl;

  /// 장비 시리얼 번호
  final String? serialNumber;

  /// 제조사
  final String? manufacturer;

  /// 구매 일자
  final DateTime? purchaseDate;

  /// 최근 점검 일자
  final DateTime? lastMaintenanceDate;

  /// 장비 상태 (available, rented, maintenance, damaged, etc)
  final String status;

  /// 대여료
  final int rentFee;

  /// 보증금
  final int depositFee;

  /// 생성 시간
  final DateTime createdAt;

  /// 대여 가능 여부
  bool get isAvailable => status == 'available' && (availableQuantity ?? 0) > 0;

  /// 대여 중 여부
  bool get isRented => status == 'rented';

  /// 점검 중 여부
  bool get isInMaintenance => status == 'maintenance';

  /// 손상 여부
  bool get isDamaged => status == 'damaged';

  /// 카테고리 한글명 반환
  String get categoryName {
    switch (category) {
      case 'camera':
        return '카메라';
      case 'lighting':
        return '조명';
      case 'audio':
        return '음향';
      case 'accessory':
        return '액세서리';
      case 'etc':
        return '기타';
      default:
        return category;
    }
  }

  /// 상태 한글명 반환
  String get statusName {
    switch (status) {
      case 'available':
        return '대여 가능';
      case 'rented':
        return '대여 중';
      case 'maintenance':
        return '점검 중';
      case 'damaged':
        return '손상됨';
      default:
        return status;
    }
  }

  /// 업데이트된 정보로 새 인스턴스 생성
  EquipmentModel copyWith({
    String? id,
    String? name,
    String? category,
    int? totalQuantity,
    int? availableQuantity,
    String? description,
    String? imagePath,
    String? imageUrl,
    String? serialNumber,
    String? manufacturer,
    DateTime? purchaseDate,
    DateTime? lastMaintenanceDate,
    String? status,
    int? rentFee,
    int? depositFee,
    DateTime? createdAt,
  }) {
    return EquipmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      serialNumber: serialNumber ?? this.serialNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      status: status ?? this.status,
      rentFee: rentFee ?? this.rentFee,
      depositFee: depositFee ?? this.depositFee,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
