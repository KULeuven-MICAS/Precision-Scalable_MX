# Precision-Scalable Microscaling (MX) Datapaths

Official repository for:

1. S. Cuyckens, X. Yi, N. S. Murthy, C. Fang, M. Verhelst, "Efficient Precision-Scalable Hardware for Microscaling (MX) Processing in Robotics Learning," *ISLPED*, 2025. [[arXiv]](https://arxiv.org/abs/2505.22404)
2. S. Cuyckens, X. Yi, R. Geens, J. Dumoulin, M. Wiesner, C. Fang, M. Verhelst, "Precision-Scalable Microscaling Datapaths with Optimized Reduction Tree for Efficient NPU Integration," *ASP-DAC*, 2026. [[arXiv]](https://arxiv.org/abs/2511.06313)

<p align="center">
  <img src="https://img.shields.io/badge/Language-SystemVerilog-blue" alt="SystemVerilog"/>
  <img src="https://img.shields.io/badge/Venue-ISLPED%202025%20%7C%20ASP--DAC%202026-green" alt="Venues"/>
  <img src="https://img.shields.io/badge/Topic-Microscaling%20%7C%20Precision--Scalable-orange" alt="MX"/>
</p>

This repository contains the SystemVerilog RTL for precision-scalable MX MAC units supporting all six MX data types (MXINT8, MXFP8 E5M2, MXFP8 E4M3, MXFP6 E3M2, MXFP6 E2M3, MXFP4 E2M1), along with their integration into the SNAX NPU platform.

## Repository Structure

```
MAC_designs/
├── FP32_addition_approach/            # MAC using FP32 addition in the reduction tree
├── Hybrid_design_approach/            # MAC with hybrid reduction tree [2]
└── Long_integer_addition_approach/    # MAC using long integer addition in the reduction tree [1]

Accelerator_integration_in_SNAX/
├── Accelerator/                       # MX tensor core: 8x8 MAC array, requantization unit, shell wrapper
├── hw/                                # SNAX platform (Snitch core, SSR, DMA, memory interfaces)
└── target/                            # Generated wrappers and external dependencies
```

## MAC Designs

Three MAC design approaches are provided, each using a different reduction tree strategy. All three support all six MX data types through precision-scalable 2-bit multipliers. Each folder contains the design files and a testbench.

- **FP32 addition approach** — Accumulates using FP32 addition with normalization, as in prior work.
- **Hybrid design approach** [2] — Combines early-accumulation from the long integer approach with FP32 addition to reduce the adder width while keeping accuracy in check.
- **Long integer addition approach** [1] — Uses early-accumulation to align products to shared MX exponents, avoiding normalization before accumulation.

## SNAX Integration

The `Accelerator_integration_in_SNAX/` directory integrates the hybrid MAC design into the SNAX platform as an MX tensor core. This includes the 8x8 spatial array of 64 MACs (`Block_PE.sv`), the requantization unit, and customized data streamers with dynamic channel gating for precision-dependent bandwidth.

## Citation

If you use this code in your work, please cite:

<details>
<summary>BibTeX</summary>
<p>

```bibtex
@inproceedings{cuyckens2025efficient,
      title={Efficient Precision-Scalable Hardware for Microscaling (MX) Processing in Robotics Learning}, 
      author={Stef Cuyckens and Xiaoling Yi and Nitish Satya Murthy and Chao Fang and Marian Verhelst},
      year={2025},
      booktitle={ISLPED},
      eprint={2505.22404},
      archivePrefix={arXiv},
      url={https://arxiv.org/abs/2505.22404}, 
}

@inproceedings{cuyckens2026precision,
      title={Precision-Scalable Microscaling Datapaths with Optimized Reduction Tree for Efficient NPU Integration}, 
      author={Stef Cuyckens and Xiaoling Yi and Robin Geens and Joren Dumoulin and Martin Wiesner and Chao Fang and Marian Verhelst},
      year={2026},
      booktitle={ASP-DAC},
      eprint={2511.06313},
      archivePrefix={arXiv},
      url={https://arxiv.org/abs/2511.06313}, 
}
```

</p>
</details>
