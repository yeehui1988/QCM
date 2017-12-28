# QCM
This repo contains C codes for quantum circuits modelling using (a) the conventional state vector representation, and (b) a compact data structure based on Heisenberg representation. As the modelling of quantum circuits on classical computer is non-intuitive, the provided source codes are constructed using raw C code without the use of any high-level library. This allows user to have better understanding on the fundamental mathematical/arithmetic operations involved.

## Background
The challenging issue in classical modelling of quantum computing systems is related to the exponential increase in resource requirement, which includes both computational and memory resources, with the increase in the number of qubits. This work explores the modelling of quantum circuits based on the Heisenberg representation that allows efficient simulation of stabilizer gates i.e., controlled-NOT gate, Hadamard gate, Phase gate as well as single-qubit measurement in computational basis, which are dominant in practical fault-tolerant quantum circuits. The conventional state-vector-based implementation is developed to serve as the golden reference model.

## Citation 
If you find QCM useful, please cite our <a href="https://www.hindawi.com/journals/ijrc/2016/5718124/" target="_blank">state vector paper</a>:

    @article{lee2016fpga,
    title={An FPGA-based quantum computing emulation framework based on serial-parallel architecture},
    author={Lee, Yee Hui and Khalil-Hani, Mohamed and Marsono, Muhammad Nadzir},
    journal={International Journal of Reconfigurable Computing},
    volume={2016},
    year={2016},
    publisher={Hindawi Publishing Corporation}
    }


## Note
The complete source codes will be uploaded soon.
