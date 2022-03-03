# A Markdown file with embedded code

## Rust block with a var

```rust
let answer=40+2;
println!("Hello, world!1");
```

Answer: «answer».

---

## Skipped block

```rust skip
let answer=40+2;
println!("Hello, world!2");
```

---

## Block with custom header for output

```rust output_header="Вітаю, світе!"
println!("Hello, world!3");
```

---

## Hidden block

```rust hide
println!("Hello, world from hidden block!");
```

---

## Raw output

```rust raw_output
println!("<b>Hello, raw world</b>!");
```

---

## Raw hidden output

```rust hide raw_output
println!("<b>Hello, hidden raw world</b>!");
```

---

## A few embedded variables in one line

```rust no_output
let a=7;
let b="test";
let c=vec![true, false];
let змінна="результат";
```

Answer: «a:03», «b», «c:?», «змінна».
