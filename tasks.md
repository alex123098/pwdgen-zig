# pwdgen

## Introduction

Implement a password generator tool that generates passwords meeting typical requirements, e.g. upper and lower case letters, numbers and special characters.
As a bonus, implement an ability to remember generated passwords and check if a password is already used.

## Requirements

- Add an ability to generate a random meaningless password.
- Generate a password using a word randomly picked from a wordlist. The password generated this way must still meet the requirements of a strong password.

## Interface

```bash

$ pwdgen --help

Usage pwdgen [options]

Options:
    -v, --verbose       Output extra information
    -h, --help          Show this help message
    -l, --length        Length of the generated password
    -w, --wordlist      Wordlist file
    -S, --no-special    Do not use special characters
    -N, --no-numbers    Do not use numbers
    -U, --no-uppercase  Do not use uppercase letters
```

### Thoughts on how to read the wordlist and pick the word efficiently

- Generate a random number `word_idx` between 0 and to max of `u64`. This is going to be the index of the word.
- Read through the wordlist file calculating the number of words `total_words_count`. If the current number equals to `word_idx`, save the word and jump over next step.
- Adjust `word_idx`: `word_idx = word_idx mod total_words_count`. And picj the word at that index.
- The length of the word should not exceed the length of the password. If it does, truncate it to the length of the password.
- If the word is shorter than the requeired length, pad it from both sides with random characters.