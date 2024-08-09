class ComplexNumber {
  final double real;
  final double imag;

  ComplexNumber(this.real, this.imag);

  ComplexNumber div(ComplexNumber other) {
    double denom = other.real * other.real + other.imag * other.imag;
    return ComplexNumber(
      (real * other.real + imag * other.imag) / denom,
      (imag * other.real - real * other.imag) / denom,
    );
  }

  @override
  String toString() {
    return '($real, ${imag}i)';
  }
}
