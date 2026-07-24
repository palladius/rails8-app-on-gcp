The final workshop will be held in `CODELAB.md` which will be converted to a Google Codelab using `claat` tool or similar.
Every page of the codelab is a H2 and it needs a frontmatter with title, tags and other shenaningans which riccardo is going to provide soon.
The final result is similar to this repo: https://codelabs.developers.google.com/codelabs/app-mod-workshop#0 (note every H2 renders into a differemt #1, 2, 3..)

## Ideation and files
You *MUST* ensure that `CODELAB.md` (long version) and `SKELETON.md` (short version) are kept in sync at all times. A change to one should signify a change to the other! Ensure this in a <!-- --> comment on top of both, for disattenti harnesses ;) The reason is that the SKELETON.md contains distilled ideas which then generate the codelab (and occasionally we piggyback stuff from Codelab to Skeleton). Riccardo and Emiliano will debate soleley on SKELETON until its set in stone.

The process is going to look like: 
1. IDEAS.md + SKELETON.md => 
2. sample CODELAB.md => 
3. 7 branches => 
4. complex codelab (which gives instructions to achieve the branch_n -> branc_(n+1) step). This requires the previous to be set in stop
5. rinse and repeat via automated reproduction of all the steps (probably instructions+branch_n will occasionally fail to bring to N+1 state so this will be slow and painful).