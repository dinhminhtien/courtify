int calculateTotal(List<int> prices) {
  return prices.fold(0, (sum, price) => sum + price);
}
