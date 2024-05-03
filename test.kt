fun fizzBuzz(n: Int) {
    fun getFizzBuzzString(number: Int): String {
        return when {
            number % 3 == 0 && number % 5 == 0 -> "FizzBuzz" number %
            3 == 0 -> "Fizz" number %
            5 == 0 -> "Buzz"
            else -> number.toString()
        }
    }for (i in 1..n) {
        println(getFizzBuzzString(i))
    }
}