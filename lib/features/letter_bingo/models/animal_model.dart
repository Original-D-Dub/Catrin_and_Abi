/// A single animal entry loaded from assets/data/animals.json.
class Animal {
  final String letter; // uppercase, e.g. 'C'
  final String name;   // e.g. 'Cat'
  final String image;  // asset path, e.g. 'assets/images/animals/cat.png'

  const Animal({
    required this.letter,
    required this.name,
    required this.image,
  });

  factory Animal.fromJson(Map<String, dynamic> json) => Animal(
        letter: json['letter'] as String,
        name: json['name'] as String,
        image: json['image'] as String,
      );
}
