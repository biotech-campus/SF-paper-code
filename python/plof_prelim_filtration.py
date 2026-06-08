import pandas as pd
import re
import argparse


PTC = {"stop_gained", "frameshift_variant", "start_lost"}
SPLICE = {"splice_acceptor_variant", "splice_donor_variant"}


def parse_exon(exon):
    if pd.isna(exon) or exon in ["", ".", "NA"]:
        return None, None

    match = re.match(r"^(\d+)(?:-\d+)?/(\d+)$", str(exon))
    if not match:
        return None, None

    return int(match.group(1)), int(match.group(2))


def split_consequence(consequence):
    if pd.isna(consequence) or consequence in ["", ".", "NA"]:
        return set()

    return set(re.split(r"[,&|]", str(consequence)))


def keep_variant(row):
    consequence = split_consequence(row["Consequence"])
    exon_num, exon_total = parse_exon(row["EXON"])

    if not (consequence & PTC or consequence & SPLICE):
        return False

    if exon_num is None or exon_total is None:
        return False

    return exon_num < exon_total - 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", required=True)
    parser.add_argument("-o", "--output", required=True)
    args = parser.parse_args()

    df = pd.read_csv(args.input, sep="\t", dtype=str)

    df["AF_joint_num"] = pd.to_numeric(df["AF_joint"], errors="coerce")

    df = df[
        (df["AF_joint_num"] < 0.01)
        & (df["CLNSIG"] == ".")
        & (df["BIOTYPE"] == "protein_coding")
    ].copy()

    df = df[df.apply(keep_variant, axis=1)].copy()

    df["NMD_prediction"] = "NMD_likely"

    df = df.drop(columns=["AF_joint_num"])

    df.to_csv(args.output, sep="\t", index=False)


if __name__ == "__main__":
    main()