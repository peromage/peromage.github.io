---
title: '[C++] Initialize std::array at Compile Time'
date: 2022-03-16 10:25:05
updated: 2022-03-16 10:25:05
categories: Coding
tags:
    - C++
    - Meta Programming
---

# Background

I've been working on optimization for some C++ code recently. One of the part is to initialize some data at compile time. Consider we have a C style enum definition:

```c++
typedef enum Foo {
    AAA = 0,
    BBB,
    CCC
} Foo_t;
```

We want to have an array of the enum with undefined initial values `999` because by default initialization the values would be `0`'s. However, `std::array` can only be initialized by initializer list, which is said:

```c++
// Partial initialization
constexpr std::array<Foo_t, 5> array {static_cast<Foo_t>(999), static_cast<Foo_t>(999)};

// Results in int equivalent: {999, 999, 0, 0, 0}
```

If there are a hundred of elements then you have to write all of them down in the list.

You can, of course, initialize it in a loop but this sacrifices runtime performance.

```c++
// Runtime initialization
std::array<Foo_t, 5> array {};
for (auto& i : array) {
    i = static_cast<Foo_t>(999);
}

// Results in int equivalent: {999, 999, 999, 999, 999}
```

# Generating code by templates

We can use recursive deduction of templates to generate our code. There is a limit that you can only do 1024 times of recursion but in my case it's enough.

The idea is to count the size to zero and use variadic argument to increase the number of arguments on each recursion. Finally the size of the array will be passed to the bottom and the variadic argument gets expanded.

It's a pretty simple trick.

```c++
template<std::size_t N, std::size_t M, typename T, typename... U>
struct ARR_IMPL {
    static constexpr auto arr = ARR_IMPL<N, M-1, T, T, U...>::arr;
};

template<std::size_t N, typename T, typename... U>
struct ARR_IMPL<N, 0, T, U...> {
    static constexpr std::array<T, N> arr {static_cast<U>(999)...};
};

template<std::size_t N, typename T>
struct ARR {
    static constexpr auto arr = ARR_IMPL<N, N-1, T, T>::arr;
};

constexpr auto array1 = ARR<5, Foo_t>::arr;
constexpr auto array2 = ARR<100, Foo_t>::arr;

// array1 results in int equivalent: {999, 999, 999, 999, 999}
// array2 results in int equivalent: {999, 999, 999, 999, 999, ...}
```
