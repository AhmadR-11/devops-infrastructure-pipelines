const { add, subtract, multiply, divide, isEven } = require('../src/math');

describe('Math Utility Unit Tests', () => {
  // Unit Test 1
  test('adds 1 + 2 to equal 3', () => {
    expect(add(1, 2)).toBe(3);
  });

  // Unit Test 2
  test('subtracts 5 - 2 to equal 3', () => {
    expect(subtract(5, 2)).toBe(3);
  });

  // Unit Test 3
  test('multiplies 3 * 4 to equal 12', () => {
    expect(multiply(3, 4)).toBe(12);
  });

  // Unit Test 4
  test('divides 10 by 2 to equal 5', () => {
    expect(divide(10, 2)).toBe(5);
  });

  // Unit Test 5
  test('checks if 4 is even', () => {
    expect(isEven(4)).toBe(true);
  });
});
