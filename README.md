# Formal Modelling and Verification of Digital Relays in Protection System

In this work we develop the formal model of a digital relay equipped with
protection, signal-dispatching, and supervisory capabilities, together with the
formal models of the communication channel and the control unit. These models
are used to analyse the protection system. The proposed methodology uses the
probabilistic model checker **PRISM** to verify the reliability, safety,
liveness, and coordination properties of relay-based protection schemes.

The repository contains **two case studies** built from the *same* reusable
device-level templates:

1. A **three-bus** distribution network (the original case study), and
2. An **IEEE nine-bus** medium-voltage network (a scalability case study that
   instantiates the same templates over a larger, two-sided-clearance
   topology).


## Repository structure

```
.
├── README.md                     This file.
├── LICENSE                       Repository license.
│
├── three-bus-model/              Case study 1: three-bus, three-relay network (MDP).
│   ├── System Model.pm             Complete three-bus system model (3 DOCRs, 3 fault points).
│   ├── Digital Relay Model.pm      Stand-alone digital-relay device model (reusable template).
│   ├── Properties_Digital_Relay    Device-level properties 
│   ├── Properties_System_Model    System-model 
│
└── nine-bus-model/               Case study 2: IEEE nine-bus, twelve-relay network (MDP).
    ├── ninebus_model_v1.pm         Nine-bus system model 
    ├── Properties_9bus.props        Full property set P1–P9 (+ Q_Safe/Q_Unsafe queries).
    └── Properties_9bus_sweep_v1.props  Quantitative sweep queries (Q_Safe, Q_Unsafe only).
```


## Requirements

- **PRISM 4.8** (probabilistic model checker) — <https://www.prismmodelchecker.org>.
  The models are MDPs written in the PRISM language.
- A **Java** runtime compatible with your PRISM build (PRISM 4.8 ships with its
  own launcher; Java 8+ recommended).
- Sufficient memory for the nine-bus model: the base parameterization builds a
  model of ~4.17 million states / ~17.66 million transitions. The reported runs
  used `-javamaxmem 12g -cuddmaxmem 8g` for the full P1–P9 batch and the quantitative sweep using the `-explicit` engine.

- *(Optional)* **STORM** — the quantitative sweep property file uses plain
  `Pmin`/`Pmax` syntax and also runs under STORM, but all numbers reported in
  the paper were produced with PRISM.

There are no other build dependencies: load a `.pm` model together with a
property file in PRISM and check the desired properties.

---

## Case study 1 — Three-bus network (`three-bus-model/`)

A three-bus, three-line distribution network with three directional
over-current relays (DOCRs). Each of the three fault points has a single
primary/backup relay pair:

| Fault | Primary | Backup |
|-------|---------|--------|
| FC1   | R1      | R3     |
| FC2   | R2      | R1     |
| FC3   | R3      | R2     |

`System Model.pm` is the complete three-bus system (≈ **11,557 states**,
**30,984 transitions**). `Digital Relay Model.pm` is the stand-alone
device-level relay model — the **reusable template** that the nine-bus model
later instantiates twelve times.

### Reproduce (three-bus)

PRISM GUI:

1. Open `three-bus-model/System Model.pm`.
2. Load a property file (`Properties_System_Model.pctl` and open
   `Digital Relay Model.pm` with `Properties_Digital_Relay`.
3. Set the failure-probability constants when prompted (the models expose
   `IED`, `BRK`, `COM`, `WD`; they default to 0 for the zero-failure liveness
   checks, and are set to `0.1` for the base dependability checks), then verify.

PRISM command line (example, from inside `three-bus-model/`):

```bash
prism "System Model.pm" "Properties_System_Model.pctl"

## Case study 2 — IEEE nine-bus network (`nine-bus-model/`)

### Purpose

A **scalability case study** that stress-tests the methodology on a larger,
medium-voltage **IEEE nine-bus** network with **6 fault points** and **12
relays**, under **two-sided line clearance** (every line is protected from both
of its ends). It answers two questions the three-bus study cannot: (i) does the
relay device model *reuse* onto a larger topology without re-deriving device
behaviour, and (ii) do the safety/liveness/coordination guarantees survive the
change from single-sided to two-sided clearance.

### Relationship to the three-bus model (reproducibility / methodology note)

The nine-bus model is **built by extending the three-bus template** in
`three-bus-model/System Model.pm`. The `Relay`, `Signal_Disp`, `Channel`,
`comm_B`, and `Sup_SV` modules are the **same templates**, instantiated **12×**
via PRISM's module-renaming mechanism — 60 of the model's 62 modules are such
instantiations. Only two parts are network-specific and re-authored:

- the **`Fault`** module (6 fault points, uniform 1/6 branching), and
- the **`Central_Unit`**, which tracks the supervisory requirement *separately
  per line end* (12 per-side flags), because a two-sided fault has **two**
  primary/backup pairs and clears only when **both** ends isolate (an AND
  condition) and fails if **either** end fails (an OR condition).

Primary → backup pairing (each relay is primary for one fault and backup for
another):

| Fault | Side A (primary → backup) | Side B (primary → backup) |
|-------|---------------------------|----------------------------|
| FC1   | R1 → R11                  | R2 → R4                    |
| FC2   | R3 → R1                   | R4 → R6                    |
| FC3   | R5 → R3                   | R6 → R8                    |
| FC4   | R7 → R5                   | R8 → R10                   |
| FC5   | R9 → R7                   | R10 → R12                  |
| FC6   | R11 → R9                  | R12 → R2                   |

### Files

- **`ninebus_model_v1.pm`** — the nine-bus system model (MDP). 
- **`Properties_9bus.props`** — the full property set, labelled to match the
  paper: **P1, P2** (liveness), **P3–P7** and **P9** (coordination / safety, one
  instance per relay or per fault side), **P8** (backup operation, one instance
  per primary/backup relationship), plus quantitative queries **Q_Safe /
  Q_Unsafe** (and per-fault `Q_Safe_FCx` / `Q_Unsafe_FCx`). The parameterization
  for each property group is documented in the file's own header.
- **`Properties_9bus_sweep_v1.props`** — just the two quantitative queries used
  for the parameter sweep:
  - `Q_Safe   : Pmin=? [ F CU=Safe_state ]`  (worst-case probability of ever reaching Safe)
  - `Q_Unsafe : Pmax=? [ F CU=Unsafe_state ]` (worst-case probability of ever reaching Unsafe)

### Model constants

The model exposes one shared communication-failure constant and a per-relay
relay-failure (`IED*`) and watchdog/internal-error (`WD*`) constant for each of
the twelve relays, all supplied via `-const`:

```
COM
IED   WD        (R1)
IEDR2 WDR2       (R2)     …    IEDR12 WDR12   (R12)
```

`Safe_state = 4` and `Unsafe_state = 5` are fixed in the model.

### Reproduce (nine-bus) — manual PRISM commands

 > Run PRISM once per property group (and, for the sweep, once per parameter value),
> as shown below. All commands assume you are inside `nine-bus-model/`. 

**1. P1 — zero-failure liveness** (all failure probabilities = 0):

```bash
prism ninebus_model_v1.pm Properties_9bus.props -prop P1 \
  -const COM=0,IED=0,IEDR2=0,IEDR3=0,IEDR4=0,IEDR5=0,IEDR6=0,IEDR7=0,IEDR8=0,IEDR9=0,IEDR10=0,IEDR11=0,IEDR12=0,WD=0,WDR2=0,WDR3=0,WDR4=0,WDR5=0,WDR6=0,WDR7=0,WDR8=0,WDR9=0,WDR10=0,WDR11=0,WDR12=0 \
  -javamaxmem 12g -cuddmaxmem 8g
```

**2. P2 and the quantitative queries — base parameterization** (every relay
failure probability and `COM` = 0.1). The *base* string used everywhere below is:

```
COM=0.1,IED=0.1,IEDR2=0.1,IEDR3=0.1,IEDR4=0.1,IEDR5=0.1,IEDR6=0.1,IEDR7=0.1,IEDR8=0.1,IEDR9=0.1,IEDR10=0.1,IEDR11=0.1,IEDR12=0.1,WD=0.1,WDR2=0.1,WDR3=0.1,WDR4=0.1,WDR5=0.1,WDR6=0.1,WDR7=0.1,WDR8=0.1,WDR9=0.1,WDR10=0.1,WDR11=0.1,WDR12=0.1
```

```bash
# P2 (liveness: every fault reaches a Safe or Unsafe verdict)
prism ninebus_model_v1.pm Properties_9bus.props -prop P2 \
  -const <BASE> -javamaxmem 12g -cuddmaxmem 8g

# Quantitative queries on the same build
prism ninebus_model_v1.pm Properties_9bus.props -prop Q_Safe,Q_Unsafe \
  -const <BASE> -javamaxmem 12g -cuddmaxmem 8g
```

**3. P3–P7 and P9 — base parameterization.** These 66 properties (P3_R1..R12,
P4/P5/P6/P7_FC1A..FC6B, P9_FC1..FC6) are all checked against the single base
build. Check them together:

```bash
prism ninebus_model_v1.pm Properties_9bus.props \
  -prop P3_R1,P3_R2,...,P9_FC6 \
  -const <BASE> -javamaxmem 12g -cuddmaxmem 8g
```

(or check any subset with `-prop <name>`; the property names are listed in
`Properties_9bus.props`).

**4. P8 — backup operation, one build per relationship.** For each
relationship, **only that relationship's primary relay** has nonzero failure
(`IEDx = WDx = 0.1`); every other relay = 0 and `COM = 0`. The primary relay per
relationship is:

| Property | Primary relay | Constants set to 0.1 |
|----------|---------------|-----------------------|
| P8_FC1A  | R1  | `IED,WD`       |
| P8_FC1B  | R2  | `IEDR2,WDR2`   |
| P8_FC2A  | R3  | `IEDR3,WDR3`   |
| P8_FC2B  | R4  | `IEDR4,WDR4`   |
| P8_FC3A  | R5  | `IEDR5,WDR5`   |
| P8_FC3B  | R6  | `IEDR6,WDR6`   |
| P8_FC4A  | R7  | `IEDR7,WDR7`   |
| P8_FC4B  | R8  | `IEDR8,WDR8`   |
| P8_FC5A  | R9  | `IEDR9,WDR9`   |
| P8_FC5B  | R10 | `IEDR10,WDR10` |
| P8_FC6A  | R11 | `IEDR11,WDR11` |
| P8_FC6B  | R12 | `IEDR12,WDR12` |

Example (P8_FC1A — primary R1):

```bash
prism ninebus_model_v1.pm Properties_9bus.props -prop P8_FC1A \
  -const COM=0,IED=0.1,WD=0.1,IEDR2=0,IEDR3=0,IEDR4=0,IEDR5=0,IEDR6=0,IEDR7=0,IEDR8=0,IEDR9=0,IEDR10=0,IEDR11=0,IEDR12=0,WDR2=0,WDR3=0,WDR4=0,WDR5=0,WDR6=0,WDR7=0,WDR8=0,WDR9=0,WDR10=0,WDR11=0,WDR12=0 \
  -javamaxmem 12g -cuddmaxmem 8g
```

For the other eleven, set that relationship's primary `IEDx,WDx = 0.1` (from the
table above) and leave all remaining `IED*`, `WD*` and `COM` at 0.

### Reproduce (nine-bus) — the quantitative parameter sweep

The sweep re-runs `Properties_9bus_sweep_v1.props` (`Q_Safe`, `Q_Unsafe`) once
per parameter value. Both sweeps use the value set

```
{ 0.0, 0.2, 0.4, 0.6, 0.8, 1.0 }
```

and hold every non-swept probability at the baseline **0.1**.

**Sweep 1 — communication failure (COM).** Vary `COM` over the six values; hold
every `IED*` and every `WD*` at 0.1. For each value `v`:

```bash
prism ninebus_model_v1.pm Properties_9bus_sweep_v1.props -prop Q_Safe,Q_Unsafe \
  -const COM=v,IED=0.1,IEDR2=0.1,IEDR3=0.1,IEDR4=0.1,IEDR5=0.1,IEDR6=0.1,IEDR7=0.1,IEDR8=0.1,IEDR9=0.1,IEDR10=0.1,IEDR11=0.1,IEDR12=0.1,WD=0.1,WDR2=0.1,WDR3=0.1,WDR4=0.1,WDR5=0.1,WDR6=0.1,WDR7=0.1,WDR8=0.1,WDR9=0.1,WDR10=0.1,WDR11=0.1,WDR12=0.1 \
  -javamaxmem 12g -cuddmaxmem 8g
```

i.e. run the command six times, substituting `COM=0.0`, `0.2`, `0.4`, `0.6`,
`0.8`, `1.0`.

**Sweep 2 — relay failure (IED).** Vary **all twelve** `IED*` constants
*together* over the six values; hold `COM` and every `WD*` at 0.1. For each
value `v`, set `IED=v,IEDR2=v,…,IEDR12=v`:

```bash
prism ninebus_model_v1.pm Properties_9bus_sweep_v1.props -prop Q_Safe,Q_Unsafe \
  -const COM=0.1,IED=v,IEDR2=v,IEDR3=v,IEDR4=v,IEDR5=v,IEDR6=v,IEDR7=v,IEDR8=v,IEDR9=v,IEDR10=v,IEDR11=v,IEDR12=v,WD=0.1,WDR2=0.1,WDR3=0.1,WDR4=0.1,WDR5=0.1,WDR6=0.1,WDR7=0.1,WDR8=0.1,WDR9=0.1,WDR10=0.1,WDR11=0.1,WDR12=0.1 \
  -javamaxmem 12g -cuddmaxmem 8g
```

again once per value `v ∈ {0.0, 0.2, 0.4, 0.6, 0.8, 1.0}`.

`Q_Safe` reports `Pmin` (worst-case probability of reaching Safe) and `Q_Unsafe`
reports `Pmax` (worst-case probability of reaching Unsafe); these were tabulated
and plotted by hand from PRISM's `Result:` lines.


## License

See [LICENSE](LICENSE).
