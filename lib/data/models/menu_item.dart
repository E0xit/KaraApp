class MenuItem {
  final String id;
  final String name;
  final String category;
  final int price;
  final bool customizable;

  const MenuItem(
    this.id,
    this.name,
    this.category,
    this.price, {
    this.customizable = false,
  });
}