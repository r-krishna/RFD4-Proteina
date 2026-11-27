"""In PyMOL, set cif_keepinmemory before loading the generated CIF, then run this file."""

from pymol import CmdException, cmd
from pymol.querying import cif_get_array


def show_rfd4_motif(object_name):
    """Select coordinate-conditioned atoms from one RFD4-generated CIF."""
    if object_name not in cmd.get_names("objects"):
        raise CmdException("Pass the name of the loaded CIF object.")
    ids = cif_get_array(object_name, "_atom_site.id")
    regions = cif_get_array(object_name, "_atom_site.annotation_src-coordinate-conditioned-region_1_atom")
    if not ids or not regions or len(ids) != len(regions):
        raise CmdException("Load the original generated CIF with cif_keepinmemory enabled.")
    selected_ids = [int(atom_id) for atom_id, region in zip(ids, regions) if region not in (None, "", ".", "?")]
    cmd.select_list("motif_atoms", object_name, selected_ids, mode="id")
    cmd.select("motif_residues", "byres (motif_atoms and polymer.protein)")
    cmd.color("gray75", object_name)
    cmd.show("sticks", "motif_residues")
    cmd.color("magenta", "motif_atoms")
    cmd.show("spheres", "motif_atoms and elem Zn")
    print(f"Selected {cmd.count_atoms('motif_atoms')} coordinate-conditioned atoms in {object_name}.")


cmd.extend("show_rfd4_motif", show_rfd4_motif)
