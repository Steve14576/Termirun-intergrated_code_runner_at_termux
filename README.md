## Termirun-intergrated_code_runner_at_termux
```
- Bugs concerning failure in execution of R, Fortran.
- There might be delay in detailed README within tha pack from the general README displayed below.
- Havent figured out how or where should Python libraries be installed.
```

- Generated with Doubao A.I.

- `termirun.sh`, A ready-to-use Shell Script tool aiming to run code files(`c,cpp,java,py,fortran,r` and extending...) using `Termux` on `Android(either root or unroot)` devices, convenitntly, by encasing the calls for multiple compilers into simple unified commands.

- Each `termirun` script works with 3 folders:  
  1. the "seat", where `termirun` script sits and your terminal `cd` at.(for unrooted users, better if under `～/` and given `chomod +777`)
  2. the "working" folder, where the code you work with file is stored.
  3. the "bins" folder, where the compile product is stored and executed from.(for unrooted users, better if under `～/` and given `chomod +777`)
  4. The termirun script, if set up properly, each time when tieggered, compiles one code file from your "working" folder to the "bins" folder and autometically executes it.

- Recommending `termirun`'s association with `Termux`, `Acode`, `Acodex-Terminal`(optional), `MT Manager`(optional).

- Do mind the mis-renaming, the script of all versions has fullname `termirun.sh`, not base name. The extra suffix `.sh` could be automatically attached druing transfer process(which makes the fullname`termirun.sh.sh`, which completely disables it). Some programmes might not acknowledge the ommition of `.sh`, but Termux is not one of them.
  - If its **visible** name on an Android device is `termirun.sh`, just rename it to `termirun`, the icon might change, but trust me, it's fine.

- Beginner firendly(as you can tell I am a beginner myself)

- Secondary `README.md` file within the zip packages each,more detailed about settings, guidance, so on.
  
- The releases are in bilingual support, *Chinese* and *English*, identically functional.

- It is born only because the author simlpy wants to use his Android tablet to do coding works, and cannot find ways to simlpy set up a "run" button in Acode.

- Hell knows, it started in about 60 lines of codes okey, then 120, then 300, 500, 700, 1200, and I was like here goes nothing just say whethre its usable Fuiyoh~

- Praise( )king the king of( )
