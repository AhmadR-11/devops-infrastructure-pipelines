// Simple math operations to fulfill the 5 Unit Tests requirement
function add(a, b) {
  return a + b;
}

function subtract(a, b) {
  return a - b;
}

function multiply(a, b) {
  return a * b;
}

function divide(a, b) {
  if (b === 0) throw new Error("Cannot divide by zero");
  return a / b;
}

function isEven(num) {
  return num % 2 === 0;
}

// ---------------------------------------------------------
// INTENTIONALLY UNTESTED CODE TO FAIL THE QUALITY GATE
// ---------------------------------------------------------
function untestedComplexLogic(a) {
  if (a > 10) {
    console.log("This is uncovered line 1");
  } else {
    console.log("This is uncovered line 2");
  }
  for (let i = 0; i < 5; i++) {
    console.log("Uncovered loop " + i);
  }
  return false;
}

module.exports = { add, subtract, multiply, divide, isEven, untestedComplexLogic };
