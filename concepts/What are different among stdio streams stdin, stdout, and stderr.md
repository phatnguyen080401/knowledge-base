## stdin (Standard Input)

- **File Descriptor:** `0`
    
- **Purpose:** This is the stream from which the program **reads** input data.
    
- **Default Source:** Your **keyboard**.
    
- **Common Function:** `scanf()`, `fgets()`, or `getchar()`.
    
- **Redirection:** You can tell a program to read from a file instead of the keyboard using the `<` operator (e.g., `./program < input.txt`).
    

## stdout (Standard Output)

- **File Descriptor:** `1`
    
- **Purpose:** This is the stream where the program **writes** its normal operational data.
    
- **Default Destination:** Your **terminal screen**.
    
- **Common Function:** `printf()`, `puts()`, or `putchar()`.
    
- **Buffering:** Typically **line-buffered**. This means the text might not show up on the screen until a newline character (`\n`) is encountered or the buffer is full.
    
- **Redirection:** You can save this output to a file using the `>` operator (e.g., `./program > output.txt`).
    

## stderr (Standard Error)

- **File Descriptor:** `2`
    
- **Purpose:** This is a separate stream specifically for **error messages** or diagnostics.
    
- **Default Destination:** Also your **terminal screen**.
    
- **Common Function:** `fprintf(stderr, "Error message\n");`.
    
- **Buffering:** Usually **unbuffered**. Errors are sent to the screen immediately because, in a crash, you don't want the error message stuck in a buffer that never gets flushed.
    
- **Redirection:** You can redirect errors separately from normal output using `2>` (e.g., `./program 2> errors.log`).
---

### Key Comparison Table

|**Feature**|**stdin**|**stdout**|**stderr**|
|---|---|---|---|
|**Full Name**|Standard Input|Standard Output|Standard Error|
|**Direction**|Input (Into program)|Output (From program)|Output (From program)|
|**File Descriptor**|`0`|`1`|`2`|
|**Standard Use**|Receiving user data|Normal program results|Error logs/Warnings|
|**Buffering**|Line-buffered|Line-buffered|Unbuffered (Immediate)|
### Why separate stdout and stderr?

The biggest reason is **piping**. If you want to send the output of Program A into Program B, you don't want error messages mixed in with the data.

> **Example:** If you run `ls | grep "txt"`, you only want the filenames to go to `grep`. If `ls` hits an error (like a permission issue), `stderr` ensures that the error message prints to your screen instead of being sent into the `grep` command.