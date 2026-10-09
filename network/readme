#Power-efficient neural network with artificial dendrites

## Environmental requirements
```
python 3.8.5
pytorch 1.8.0
torchvision 0.9.0
```

## The steps are as follows
### Training：
```bash
CUDA_VISIBLE_DEVICES=2 python main.py --num_workers 4  --lr 0.005   --batch_size 128  --scheduler multi_step   --save_root results   --num_epochs  100
CUDA_VISIBLE_DEVICES=2 python main.py --num_workers 4  --lr 0.005   --batch_size 128  --scheduler multi_step   --save_root results   --num_epochs  100 --pretrained_path results/ann/svhn/checkpoint/last.pth
CUDA_VISIBLE_DEVICES=2 python main.py --num_workers 4  --lr 0.005   --batch_size 128  --scheduler multi_step   --save_root results   --num_epochs  100 --pretrained_path results/ann/svhn/checkpoint/last.pth
CUDA_VISIBLE_DEVICES=2 python main.py --num_workers 4  --lr 0.005   --batch_size 128  --scheduler multi_step   --save_root results   --num_epochs  100 --pretrained_path results/ann/svhn/checkpoint/last.pth
CUDA_VISIBLE_DEVICES=2 python main.py --num_workers 4  --lr 0.0005   --batch_size 128  --scheduler multi_step   --save_root results   --num_epochs  100 --pretrained_path results/ann/svhn/checkpoint/last.pth
CUDA_VISIBLE_DEVICES=2 python main.py --num_workers 4  --lr 0.0005   --batch_size 128  --scheduler multi_step   --save_root results   --num_epochs  100 --pretrained_path results/ann/svhn/checkpoint/last.pth 
```

### Test：
```bash
CUDA_VISIBLE_DEVICES=2  python main.py --num_workers 4  --batch_size 128  --eval True --pretrained_path results/ann/svhn/checkpoint/last.pth
```

# User Manual: cient neural network with artificial dendrites
## 1. Environment Requirements
Ensure the following dependencies are installed with the specified versions before running the code:
*   **Python**: 3.8.5
*   **PyTorch**: 1.8.0
*   **Torchvision**: 0.9.0
It is recommended to use Anaconda to set up the environment:
```bash
conda create -n dendrite_net python=3.8.5
conda activate dendrite_net
conda install pytorch=1.8.0 torchvision=0.9.0 -c pytorch
```
## 2. Training Steps
The training process involves multiple stages, likely involving iterative fine-tuning. Execute the following commands in order from the project's root directory.
**Note**:
*   `CUDA_VISIBLE_DEVICES=2` specifies the use of GPU #2. Modify this number according to your hardware availability.
*   Ensure the path specified in `--pretrained_path` exists before running the corresponding commands.
### Stage 1: Initial Training
Run the following command to start training from scratch:
```bash
CUDA_VISIBLE_DEVICES=2 python main.py --num_workers 4  --lr 0.005   --batch_size 128  --scheduler multi_step   --save_root results   --num_epochs  100
```
### Stage 2: Iterative Fine-tuning
Subsequent steps require loading weights from previous stages. Execute the commands sequentially (note the change in learning rate):
1.  **Fine-tuning Round 1** (Learning Rate = 0.005):
    ```bash
    CUDA_VISIBLE_DEVICES=2 python main.py --num_workers 4  --lr 0.005   --batch_size 128  --scheduler multi_step   --save_root results   --num_epochs  100 --pretrained_path results/ann/svhn/checkpoint/last.pth
    ```
2.  **Fine-tuning Round 2** (Learning Rate = 0.005):
    ```bash
    CUDA_VISIBLE_DEVICES=2 python main.py --num_workers 4  --lr 0.005   --batch_size 128  --scheduler multi_step   --save_root results   --num_epochs  100 --pretrained_path results/ann/svhn/checkpoint/last.pth
    ```
3.  **Fine-tuning Round 3** (Learning Rate = 0.005):
    ```bash
    CUDA_VISIBLE_DEVICES=2 python main.py --num_workers 4  --lr 0.005   --batch_size 128  --scheduler multi_step   --save_root results   --num_epochs  100 --pretrained_path results/ann/svhn/checkpoint/last.pth
    ```
4.  **Fine-tuning Round 4** (Learning Rate = 0.0005):
    ```bash
    CUDA_VISIBLE_DEVICES=2 python main.py --num_workers 4  --lr 0.0005   --batch_size 128  --scheduler multi_step   --save_root results   --num_epochs  100 --pretrained_path results/ann/svhn/checkpoint/last.pth
    ```
5.  **Fine-tuning Round 5** (Learning Rate = 0.0005):
    ```bash
    CUDA_VISIBLE_DEVICES=2 python main.py --num_workers 4  --lr 0.0005   --batch_size 128  --scheduler multi_step   --save_root results   --num_epochs  100 --pretrained_path results/ann/svhn/checkpoint/last.pth 
    ```
## 3. Testing
After training is complete, run the following command to evaluate the model:
```bash
CUDA_VISIBLE_DEVICES=2  python main.py --num_workers 4  --batch_size 128  --eval True --pretrained_path results/ann/svhn/checkpoint/last.pth
```
## 4. Parameter Description
| Parameter | Example Value | Description |
| :--- | :--- | :--- |
| `--num_workers` | 4 | Number of subprocesses used for data loading. |
| `--lr` | 0.005 / 0.0005 | Learning rate. It is recommended to decrease this in later stages. |
| `--batch_size` | 128 | Batch size for training/testing. |
| `--scheduler` | multi_step | Learning rate scheduling strategy. |
| `--save_root` | results | Root directory to save results. |
| `--num_epochs` | 100 | Number of training epochs. |
| `--pretrained_path` | .../last.pth | Path to the pre-trained model weights. If not specified, training starts from scratch. |
| `--eval` | True | Enable evaluation mode. |
## 5. Important Notes
1.  **File Path**: Ensure that the weight file (`last.pth`) exists at the specified `--pretrained_path` before running fine-tuning or testing commands.
2.  **GPU Configuration**: If you encounter "CUDA out of memory" errors, try reducing the `--batch_size`.
3.  **Device Selection**: The commands provided use GPU #2 (`CUDA_VISIBLE_DEVICES=2`). Change this to `0` or another ID depending on your available devices.

The data could be found at http://101.6.93.12:10007/l/uFjZkh
http://101.6.93.12:10007/l/uFjZkh
