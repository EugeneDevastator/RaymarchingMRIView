# -*- coding: utf-8 -*-
"""
Created on Sun Jul  4 19:05:03 2021

@author: DaveAstator
"""

import cv2
import glob
import matplotlib as plt

root = '.\'

files = glob.glob(root+'\\*')

count = 15
side = count*256
big = np.zeros((side,side,3),uint8)
fid = 0
for i in range(0,count):
    for k in range (0,count):
        if fid >= len(files):
            break
        im = cv2.imread(files[fid], cv2.IMREAD_UNCHANGED)[:,:,:3]
        big[i*256:(i+1)*256,k*256:(k+1)*256,:]=im
        fid=fid+1



plt.pyplot.imshow(big)
cv2.imwrite('.\MRI2015.png',big)
print(type(im))