# diagram.nvim mermaid demo

Open this file, place the cursor inside any `mermaid` code block, leave insert
mode (or just sit still in normal mode), and the diagram should render below
the block via `image.nvim`.

If nothing shows up, run `:checkhealth image` and `:messages`.

## Flowchart

```mermaid
flowchart LR
    A[edit buffer] -->|InsertLeave| B(diagram.nvim)
    B --> C[mmdc]
    C --> D[(PNG cache)]
    D --> E{image.nvim}
    E -- kitty proto --> F[Ghostty renders]
```

## Sequence

```mermaid
sequenceDiagram
    participant U as User
    participant N as Neovim
    participant D as diagram.nvim
    participant M as mmdc
    participant I as image.nvim
    U->>N: edits mermaid block
    N->>D: TextChanged / InsertLeave
    D->>M: shell out source
    M-->>D: PNG path
    D->>I: render(path, win, line)
    I-->>U: image on screen
```

## State

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Rendering: cursor enters block
    Rendering --> Cached: mmdc success
    Rendering --> Error: mmdc fail
    Cached --> Idle: cursor leaves
    Error --> Idle: clear
```

## Class

```mermaid
classDiagram
    class Renderer {
      +render(source) Image
      -cache_dir string
    }
    class Integration {
      +scan(buf) Block[]
      +dispatch(block)
    }
    Integration --> Renderer : uses
    class Markdown
    class Neorg
    Markdown --|> Integration
    Neorg --|> Integration
```

## Pie

```mermaid
pie showData
    title where the time goes
    "writing code" : 40
    "reading code" : 35
    "fighting tooling" : 25
```

## Gantt

```mermaid
gantt
    title Setup timeline
    dateFormat YYYY-MM-DD
    section Install
    brew imagemagick   :a1, 2026-05-11, 1d
    restart nvim       :a2, after a1, 1d
    section Verify
    open this file     :b1, after a2, 1d
    tweak theme/scale  :b2, after b1, 2d
```
