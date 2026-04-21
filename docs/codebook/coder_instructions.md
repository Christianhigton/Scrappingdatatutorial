# Coder Instructions: Weight Stigma in Nutrition-Related Posts

## Aim
Classify each post for weight stigma using the codebook in this folder.

## Core principles
1. Code stigma separately from sentiment. A negative tone is not automatically stigma.
2. Use the full post context before assigning codes.
3. Assign stigma_binary = 1 when any stigma category applies.
4. Assign stigma_binary = 0 when no stigma categories apply.
5. Mark neutral_supportive = 1 when language is clearly non-stigmatising.

## Coding steps
1. Read post text once for context.
2. Decide stigma_binary (1/0).
3. Apply all relevant multi-codes (1 = present, 0 = absent).
4. Add short justification in notes for difficult cases.

## Independent coding
Each coder should complete their own file without discussing coding decisions until reliability is calculated.

## File naming
Save your file as docs/codebook/ratings/coder_<initials>.csv
