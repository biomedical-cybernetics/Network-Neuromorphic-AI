import pickle
import numpy as np


def inspect_pkl_file(file_path):
    print(f"Loading file: {file_path} ...\n")

    try:
        # Open the file in binary read mode
        with open(file_path, 'rb') as f:
            # Load the dictionary
            weight_dict = pickle.load(f)

        print("Load successful! File content overview:")
        print("-" * 50)

        # 1. Check if the content is a dictionary
        if not isinstance(weight_dict, dict):
            print(f"Note: The file content is not a dictionary, but {type(weight_dict)}")
            return

        # 2. Iterate through the dictionary and print info
        print(f"Total number of keys: {len(weight_dict)} \n")

        for key, value in weight_dict.items():
            # Check if the value is a numpy array
            if isinstance(value, np.ndarray):
                # Print key name, shape, and data type
                print(f"Key: {key}")
                print(f"  - Type: numpy.ndarray")
                print(f"  - Shape: {value.shape}")
                print(f"  - Dtype: {value.dtype}")
                # Optional: Print a preview of the values
                # print(f"  - Preview: {value.flatten()[:5]}...")
                print("-" * 30)
            else:
                print(f"Key: {key}")
                print(f"  - Type: {type(value)}")
                print("-" * 30)

        # 3. Example: How to extract a specific weight matrix
        print("\nExtraction Example:")
        # Get the first key
        first_key = list(weight_dict.keys())[0]
        first_array = weight_dict[first_key]
        print(f"Extracted data from '{first_key}', shape is {first_array.shape}.")
        print("First 3 values of this matrix:", first_array.flatten()[:3])

    except FileNotFoundError:
        print(f"Error: File not found '{file_path}'")
    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == '__main__':
    # Specify your filename here
    pkl_file = 'model_weights.pkl'
    inspect_pkl_file(pkl_file)


# log:

# Loading file: model_weights.pkl ...
#
# Load successful! File content overview:
# --------------------------------------------------
# Total number of keys: 13
#
# Key: layer1.liners.0.weight
#   - Type: numpy.ndarray
#   - Shape: (500, 320)
#   - Dtype: float32
# ------------------------------
# Key: layer1.liners.1.weight
#   - Type: numpy.ndarray
#   - Shape: (500, 320)
#   - Dtype: float32
# ------------------------------
# Key: layer1.liners.2.weight
#   - Type: numpy.ndarray
#   - Shape: (500, 320)
#   - Dtype: float32
# ------------------------------
# Key: layer1.liners.3.weight
#   - Type: numpy.ndarray
#   - Shape: (500, 384)
#   - Dtype: float32
# ------------------------------
# Key: layer1.liners.4.weight
#   - Type: numpy.ndarray
#   - Shape: (500, 384)
#   - Dtype: float32
# ------------------------------
# Key: layer1.liners.5.weight
#   - Type: numpy.ndarray
#   - Shape: (500, 384)
#   - Dtype: float32
# ------------------------------
# Key: layer1.liners.6.weight
#   - Type: numpy.ndarray
#   - Shape: (500, 320)
#   - Dtype: float32
# ------------------------------
# Key: layer1.liners.7.weight
#   - Type: numpy.ndarray
#   - Shape: (500, 320)
#   - Dtype: float32
# ------------------------------
# Key: layer1.liners.8.weight
#   - Type: numpy.ndarray
#   - Shape: (500, 320)
#   - Dtype: float32
# ------------------------------
# Key: layer2.liners.0.weight
#   - Type: numpy.ndarray
#   - Shape: (10, 125)
#   - Dtype: float32
# ------------------------------
# Key: layer2.liners.1.weight
#   - Type: numpy.ndarray
#   - Shape: (10, 125)
#   - Dtype: float32
# ------------------------------
# Key: layer2.liners.2.weight
#   - Type: numpy.ndarray
#   - Shape: (10, 125)
#   - Dtype: float32
# ------------------------------
# Key: layer2.liners.3.weight
#   - Type: numpy.ndarray
#   - Shape: (10, 125)
#   - Dtype: float32
# ------------------------------
#
# Extraction Example:
# Extracted data from 'layer1.liners.0.weight', shape is (500, 320).
# First 3 values of this matrix: [-0.00315593 -0.00150206  0.00241595]
