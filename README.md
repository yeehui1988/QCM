# QCM
This repo contains source codes for quantum circuits modelling (using state vector and Heisenberg representations) on classical computing platforms. As the modelling of quantum circuits on classical computer is non-intuitive, the provided source codes are constructed using raw C and Verilog HDL codes (for software simulation and FPGA emulation purposes) without the use of any high-level library. This allows user to have better understanding on the fundamental mathematical/arithmetic operations involved.

## Background
The challenging issue in classical modelling of quantum computing systems is related to the exponential increase in resource requirement, which includes both computational and memory resources, with the increase in the number of qubits. This work explores two data structures for quantum circuit modelling: (a) State vector representation; and (b) Heisenberg representation. 

State vector model is the conventional approach for quantum computing modelling, whereas Heisenberg model is a compact data structure that facilicitates efficient modelling of stabilizer gates that are dominant in practical fault-tolerant quantum circuits. In this work, the quantum circuit modelling is implemented through (i) Software simulation method; and (ii) FPGA emulation method.

Kindly refer to our <a href="https://www.hindawi.com/journals/ijrc/2016/5718124/" target="_blank">state vector emulation paper</a> and <a href="https://protect-au.mimecast.com/s/4mDiCQnzP0tlkyWWuM8Dza?domain=em.rdcu.be" target="_blank">Heisenberg algorithm paper</a> for detailed descriptions of the implemented models and algorithms.

## Citation 
If you find QCM useful, please cite our published papers:

    @article{lee2016fpga,
    title={An FPGA-based quantum computing emulation framework based on serial-parallel architecture},
    author={Lee, Yee Hui and Khalil-Hani, Mohamed and Marsono, Muhammad Nadzir},
    journal={International Journal of Reconfigurable Computing},
    volume={2016},
    year={2016},
    publisher={Hindawi Publishing Corporation}
    }

    @article{lee2018improved,
    title={Improved quantum circuit modelling based on Heisenberg representation},
    author={Lee, Yee Hui and Khalil-Hani, Mohamed and Marsono, Muhammad Nadzir},
    journal={Quantum Information Processing},
    volume={17},
    year={2018},
    publisher={Springer US}
    }

## Note
The complete Verilog HDL codes for FPGA emulation of quantum circuits will be uploaded soon.
