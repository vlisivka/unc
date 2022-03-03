# A Markdown file with embedded code

## Rust block with a var

```rust
let answer=40+2;
println!("Hello, world!1");
```

```
Hello, world!1

```


Answer: 42.

---

## Skipped block

```rust
let answer=40+2;
println!("Hello, world!2");
```

---

## Block with custom header for output

```rust
println!("Hello, world!3");
```
Вітаю, світе!

```
Hello, world!3

```


---

## Hidden block


```
Hello, world from hidden block!

```


---

## Raw output

```rust
println!("<b>Hello, raw world</b>!");
```
<b>Hello, raw world</b>!

---

## Raw hidden output

<b>Hello, hidden raw world</b>!

---

## A few embedded variables in one line

```rust
let a=7;
let b="test";
let c=vec![true, false];
let змінна="результат";
```

Answer: 007, test, [true, false], результат.
