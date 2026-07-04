import sys

#u folderu u kome je ovaj fajl, treba prekopirati i lenaCorrupted.dat
#program se pokreće komandom: python signal_to_img.py "ime_fajla", bez ""
#fajl treba prekopirati iz lokacija_projekta/ime_projekta.sim/sim_1/behav/xsim/xsim_dump.vcd u lokalni folder
#sa vrha prekopiranog fajla treba obrisati prvih 20tak linija, koji su samo dodatne informacije o signalu:

#primer xsim_dump.vcd fajla
"""
$date          <= prva linija fajla
Wed Jan  4 19:12:48 2023
$end
$version
2020.2
$end
$timescale
1ps
$end
$scope module main_tb $end
$scope module DUT $end
$var wire 8 ! median_out [7:0] $end
$upscope $end
$upscope $end
$enddefinitions $end
#0
$dumpvars
bx !
$end
#64000
b0 !
#857832000    <= do ove linije treba brisati, pre toga su irrelevantne informacije, ovu liniju ostaviti
b10001010 !
#858168000
b10000110 !
...
"""

def binaryToDecimal(binary):
    decimal, i = 0, 0
    while(binary != 0):
        dec = binary % 10
        decimal = decimal + dec * pow(2, i)
        binary = binary//10
        i += 1
    return decimal

#učitavanje fajla imenovanog u komandnoj liniji
data = open(sys.argv[1], "r")

pixeli = []

#na početak se dodaje proizvoljan broj crnih piksela, jer to median filter "ne dira",
#bez ovih piksela slika bi bila šiftovana na gore i bio bi manjak pixela
#p zavisi u suštini od dimenzija kernela, za 3x3 je 256 + 1, 5x5 je 2*256 + 2, itd.
p = 256 + 1
for i in range(0,p ):
    pixeli.append(0)

counter = 0
razlika = 0
pixel = 0
prosli_trenutak = 0
#perioda kloka u ps
tclk = 8000
#broj klokova do sledeće očekivanje promene signala pri ispisu jednog pixela
#meni je 14 jer se toliko stanja promeni do sledećeg ispisa iz medijan filtera
n = 1

for line in data.readlines():
    if(counter == 0):
        #odsecanje vodećeg # karaktera u liniji koja opisuje vreme
        vrednost = int(line[1:])
        prosli_trenutak = vrednost
    if(counter % 2 == 0 and counter > 1):
        #odsecanje vodećeg # karaktera u liniji koja opisuje vreme
        vrednost = int(float(line[1:]))
        #razlika se računa jer je moguće da je signal konstantan duži period vremena,
        #u tom slučaju neophodno je ponoviti dati pixel proporcionalan broj puta
        #print(vrednost-prosli_trenutak)
        razlika = (vrednost - prosli_trenutak) // (tclk * n)
        #print("razlika:", razlika)
        #trenutna vrednost vremena postaje prošlost, radi računanja razlik
        prosli_trenutak = vrednost 
        #koliko dugo je isti izlaz median filtera, toliko puta se ponavlja piksel
        for i in range(razlika):
            pixeli.append(pixel)

    elif counter % 2 == 1:
        #pamtimo vrednost pixela, ta nam informacija treba tek za sledeću inkrementaciju
        #for petlje, jer još ne znamo koliko dugo traje ova vrednost
        #sa početka se skida "b" karakter koji signalizira da se radi o binarnom broju
        #sa kraja se skidaju 2 karaktera jer su " !" i smetaju konverziji
        pixel = binaryToDecimal(int(line[1:-2]))
        #print(pixel)
    
    counter += 1

#isti proces nadodavanja neophodan je i na kraju
pp = 256 + 2+1
for i in range(0,pp):
    pixeli.append(0)

#dalje je kod u suštini deo fajlova iz projekta
import numpy as np
import scipy.signal as signal
import struct as struct
import matplotlib.pyplot as plt

IMAGE_SIZE = 256
#u slučaju da smo previše paddovali sa nulama
#print("duzina:",len(pixeli))
pixeli = pixeli[:IMAGE_SIZE*IMAGE_SIZE]
#print("duzina:",len(pixeli))
#ispisivanje pixela u stdout, korisno za poredjenje sa python medianom, pomoći diff komande
#for pixel in pixeli: 
#    print(pixel)

fpgaImage = np.zeros([IMAGE_SIZE,IMAGE_SIZE ])
fpgaImage = np.reshape(np.array(pixeli), [IMAGE_SIZE, IMAGE_SIZE])
np.set_printoptions(threshold=sys.maxsize)
#print(fpgaImage) 
plt.imshow(fpgaImage, cmap='gray', vmin=0, vmax=255)
plt.show()

swImage = plt.imread('lenaCorrupted.bmp')

plt.imshow(swImage, cmap='gray', vmin=0, vmax=255)
plt.show()

swImageDenoised = signal.medfilt2d(swImage, 3)

#ispis python medijana, služi kao referenca za razliku
"""
for line in swImageDenoised:
    for pix in line:
        print(pix)
"""
plt.imshow(swImageDenoised, cmap='gray', vmin=0, vmax=255)
np.set_printoptions(threshold=sys.maxsize)
#print(swImageDenoised)
x = fpgaImage - swImageDenoised
print(x)
plt.show()


