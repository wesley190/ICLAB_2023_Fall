import random
import math 

def gen_test_data(input_file_path, output_file_path):
    # Initialize file paths
    pIFile = open(input_file_path, 'w')
    pOFile = open(output_file_path, 'w')

    # Set Pattern number
    PATTERN_NUM = 1000
    pIFile.write(str(PATTERN_NUM))  # Corrected: Convert to string
    pIFile.write("\n")
    for j in range(PATTERN_NUM):
        mode = random.randint(0, 3)
        out_n = 0

        # Generate test data here

        # Generate input
        w = [random.randint(1, 7) for _ in range(6)]
        vgs = [random.randint(1, 7) for _ in range(6)]
        vds = [random.randint(1, 7) for _ in range(6)]

        # Algorithm
        gm = []
        id = []
        for k in range(6):
            if (vgs[k] - 1) > vds[k]:  # Tri mode
                if mode in [0, 2]:
                    tmp = 2 * w[k] * vds[k] / 3
                    gm.append(math.floor(tmp))
                elif mode in [1, 3]:
                    tmp = w[k] * (2 * (vgs[k] - 1) * vds[k] - vds[k] * vds[k]) / 3
                    id.append(math.floor(tmp))
            else:  # Sat mode
                if mode in [0, 2]:
                    tmp = 2 * w[k] * (vgs[k] - 1) / 3
                    gm.append(math.floor(tmp))
                elif mode in [1, 3]:
                    tmp = w[k] * (vgs[k] - 1) * (vgs[k] - 1) / 3
                    id.append(math.floor(tmp))

        if mode in [0, 2]:  # gm
            gm.sort(reverse=True)
        elif mode in [1, 3]:  # id
            id.sort(reverse=True)

        # Calculate output
        if mode == 0:
            out_n = math.floor((gm[3] + gm[4] + gm[5]) / 3)
        elif mode == 1:
            out_n = math.floor((3 * id[3] + 4 * id[4] + 5 * id[5]) / 12)
        elif mode == 2:
            out_n = math.floor((gm[0] + gm[1] + gm[2]) / 3)
        elif mode == 3:
            out_n = math.floor((3 * id[0] + 4 * id[1] + 5 * id[2]) / 12)

        # Output file
        pIFile.write(f"\n{mode}\n")
        for i in range(6):
            #pIFile.write(f"{mode}\n")
            pIFile.write(f"{w[i]} {vgs[i]} {vds[i]}\n")
        pOFile.write(f"{out_n}\n")

def main():
    gen_test_data("input.txt", "output.txt")

if __name__ == '__main__':
    main()

