# BPSK Signal Processing 

A small MATLAB toolbox for simulating BPSK (Binary Phase Shift Keying) communication systems. Includes pulse-shaping, matched filtering, and symbol detection helpers, useful for simulation and rapid prototyping.

## Files

- **`root_raised_cosine.m`** — Generates a sampled root-raised-cosine (RRC) pulse. Can be used for pulse shaping or matched filtering.  
  **Notes:** Uses a closed-form expression and replaces removable singularities with analytical limits. The pulse is normalized so that the sampled energy ≈ 1 per symbol.

- **`Dec_dev.m`** — Nearest-constellation detector.  
  **Defaults:** BPSK mapping (−1 → 0, +1 → 1).  
  **Extension:** Can be modified to accept custom constellations for QPSK, 16-QAM, etc. Vectorized for fast processing.

- **`Project_transmitter.m`** 
  **Functionality:**  
  1. Generates random bits.  
  2. Maps bits to BPSK symbols (0 → −1, 1 → +1).  
  3. Shapes the symbols using `root_raised_cosine` pulse.  
  4. Outputs the transmitted waveform for simulation or channel modeling.

- **`Project_Receiver.m`** — 
  **Functionality:**  
  1. Receives waveform (optionally with noise).  
  2. Applies matched filter (RRC pulse).  
  3. Performs symbol timing and downsampling.  
  4. Detects symbols using `Dec_dev` and maps them back to bits.  
  5. Computes bit error rate (BER) if reference bits are provided.

  - **`Sym_map.m`** — Symbol mapper.  
  **Functionality:** Maps input bits to modulation symbols. Default is BPSK (0 → −1, 1 → +1). Can be extended for higher-order modulation schemes.  


## Requirements

- **MATLAB** — [MathWorks MATLAB](https://www.mathworks.com/products/matlab.html)  

Optional: Signal Processing Toolbox (for plotting or advanced filtering functions).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
