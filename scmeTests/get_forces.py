from quippy import *
from ase import atoms
from ase.io import read,write
from ase.visualize import view
from quippy.potential import Potential
import os,sys
import numpy as np

# the quippy+ASE way of calculating energies

hexamers = read("6mer.xyz")
kcal=23.060541945
e2b = []
## Finite Difference
print("")
print("")
print("Calculating Finite Difference Forces:")

pot=Potential("IP SCME force_using_fd=True label=version_20160315",param_filename="dummy.xml")

hexa = hexamers
hexa.set_cell([50.0,50.0,50.0])
hexa.set_pbc(True)

hexa.set_calculator(pot)
e = hexa.get_potential_energy()
f = hexa.get_forces()

s = hexa.get_chemical_symbols()
for i in range(len(s)/3):
	print("H2O Nr.: ", i+1)
	print(s[3*i +0],f[3*i+0,:])
	print(s[3*i +1],f[3*i+1,:])
	print(s[3*i +2],f[3*i+2,:])

print(e)

## Analytical forces!
print("")
print("")
print("... and now analytical forces:")

pot2=Potential("IP SCME label=version_20160315",param_filename="dummy.xml")

hexa2 = hexa

hexa2.set_cell([50.0,50.0,50.0])
hexa2.set_pbc(True)

hexa2.set_calculator(pot2)
e2 = hexa2.get_potential_energy()
f2 = hexa2.get_forces()

s2 = hexa2.get_chemical_symbols()
for i in range(int(len(s)/3)):
	print("H2O Nr.: ", i+1)
	print(s2[3*i +0],f2[3*i+0,:])
	print(s2[3*i +1],f2[3*i+1,:])
	print(s2[3*i +2],f2[3*i+2,:])

print(e2)
