// David Desbiens
// Application qui traite l'arrière plan d'une image


//Cuda
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

//OpenCV
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/types_c.h>
#include <opencv2/imgproc/imgproc.hpp>
using namespace cv;


#include "stdafx.h"
#include <iostream>
#include <io.h>



struct InfoImage {
	int Compteur;
	int NEcartB;
	int NEcartV;
	int NEcartR;
};


extern "C" cudaError_t Analyser(unsigned char *Image, int x, int y, unsigned char *Echantillons, InfoImage InfoImg, char Type);
void CalculerMoyenne(String f, unsigned char Echantillons[]);

void on_BBarre(int i, void *v);
void on_VBarre(int i, void *v);
void on_RBarre(int i, void *v);


void AfficherImage();



InfoImage g_Infos;
unsigned char *g_Echantillons;
