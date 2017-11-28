// David Desbiens
// Application qui traite l'arrière plan d'une image

//Cuda
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <iostream>


//Structure qui contient le nombre d'élément dans le tableau et des différentes écart à appliquer
struct InfoImage {
	int Compteur;
	int NEcartB;
	int NEcartV;
	int NEcartR;
};


extern "C" cudaError_t Analyser(unsigned char *Image, int x, int y, unsigned char *Echantillons, InfoImage InfoImg, char Type);



//Kernel pour enlever le fond
__global__ void ChangerFond(unsigned char *Addr, unsigned char *Tab, InfoImage InfoImg)
{
	int i = (blockIdx.x * blockDim.x + threadIdx.x) * 3;
	int min = 0, max = 0;

	for (int x = 0; x < InfoImg.Compteur; x += 6) {
		//Calcule du min Bleu
		min = Tab[x] - Tab[x + 1] * InfoImg.NEcartB;
		if (min < 0)
			min = 0;
		//Calcule du max Bleu
		max = Tab[x] + Tab[x + 1] * InfoImg.NEcartB;
		if (min > 255)
			min = 255;


		if (Addr[i] >= min && Addr[i] <= max)
		{
			//Calcule du min Vert
			min = Tab[x + 2] - Tab[x + 3] * InfoImg.NEcartV;
			if (min < 0)
				min = 0;
			//Calcule du max Vert
			max = Tab[x + 2] + Tab[x + 3] * InfoImg.NEcartV;
			if (min > 255)
				min = 255;


			if (Addr[i + 1] >= min && Addr[i + 1] <= max)
			{
				//Calcule du min Rouge
				min = Tab[x + 4] - Tab[x + 5] * InfoImg.NEcartR;
				if (min < 0)
					min = 0;
				//Calcule du max Rouge
				max = Tab[x + 4] + Tab[x + 5] * InfoImg.NEcartR;
				if (min > 255)
					min = 255;

				//Mettre en blanc si rentre dans toutes les conditions
				if (Addr[i + 2] >= min && Addr[i + 2] <= max)
				{
					Addr[i] = 255;
					Addr[i + 1] = 255;
					Addr[i + 2] = 255;
				}

			}
		}
	}
}


//Kernel pour appliquer le sobel
__global__ void AppliquerSobel(unsigned char *Addr, unsigned char *Addr2, int Largeur, int gImage) {
	int i = blockIdx.x * blockDim.x + threadIdx.x;
	float SommeX = 0;
	float SommeY = 0;

	Largeur *= 3;


	//Gradient en x
	//Pixels du haut
	if (&Addr[i - Largeur - 3] >= &Addr[0])
		SommeX += (Addr[i - Largeur - 3] * -1);
	if (&Addr[i - Largeur + 3] >= &Addr[0])
		SommeX += (Addr[i - Largeur + 3]);
	//Pixels du centre
	if (i / Largeur == (i - 3) / Largeur)
		SommeX += (Addr[i - 3] * -2);
	if (i / Largeur == (i + 3) / Largeur)
		SommeX += (Addr[i + 3] * 2);
	//Pixels du bas
	if (&Addr[i + Largeur - 3] <= &Addr[gImage])
		SommeX += (Addr[i + Largeur - 3] * -1);
	if (&Addr[i + Largeur + 3] <= &Addr[gImage])
		SommeX += (Addr[i + Largeur + 3]);

	SommeX = SommeX * SommeX;


	//Gradient en y
	//Pixels du haut
	if (&Addr[i - Largeur - 3] >= &Addr[0])
		SommeY += (Addr[i - Largeur - 3] * -1);
	if (&Addr[i - Largeur] >= &Addr[0])
		SommeY += (Addr[i - Largeur] * -2);
	if (&Addr[i - Largeur + 3] >= &Addr[0])
		SommeY += (Addr[i - Largeur + 3] * -1);
	//Pixels du bas
	if (&Addr[i + Largeur - 3] <= &Addr[gImage])
		SommeY += (Addr[i + Largeur - 3]);
	if (&Addr[i + Largeur] <= &Addr[gImage])
		SommeY += (Addr[i + Largeur] * 2);
	if (&Addr[i + Largeur + 3] <= &Addr[gImage])
		SommeY += (Addr[i + Largeur + 3]);

	SommeY = SommeY * SommeY;
	

	Addr2[i] = sqrt(SommeX + SommeY);
}



/* Type
		0 : enlève la couleur du fond
		1 : applique sobel
*/
cudaError_t Analyser(unsigned char *Image, int x, int y, unsigned char *Tableau, InfoImage InfoImg, char Type)
{
	cudaError_t Erreur;
	unsigned char *AddrGPU = 0;
	unsigned char *AddrGPU2 = 0;
	unsigned char *AddrTab = 0;


	//Sélectionner le GPU
	Erreur = cudaSetDevice(0);
	if (Erreur != cudaSuccess)
	{
		std::cout << "Sélection de la carte impossible\r\n";
		return Erreur;
	}

	//Réservation de la mémoire GPU pour l'image
	Erreur = cudaMalloc((void**)&AddrGPU, x * y * 3);
	if (Erreur != cudaSuccess)
	{
		std::cout << "Allocation de la mémoire impossible\r\n";
		return Erreur;
	}

	//Copie vers la mémoire GPU de l'image
	Erreur = cudaMemcpy(AddrGPU, Image, x * y * 3, cudaMemcpyHostToDevice);
	if (Erreur != cudaSuccess)
	{
		std::cout << "Copie vers le GPU impossible\r\n";
		return Erreur;
	}




	//**********************************************************************************
	//Enlever la couleur de fond
	if (Type == 0) {
		//Allocation mémoire pour le tableau des échantillons
		Erreur = cudaMalloc((void**)&AddrTab, InfoImg.Compteur);
		if (Erreur != cudaSuccess)
		{
			std::cout << "Allocation de la mémoire impossible\r\n";
			return Erreur;
		}

		//Copie vers la mémoire GPU de l'image
		Erreur = cudaMemcpy(AddrTab, Tableau, InfoImg.Compteur, cudaMemcpyHostToDevice);
		if (Erreur != cudaSuccess)
		{
			std::cout << "Copie vers le GPU impossible\r\n";
			return Erreur;
		}
		//Calcul du nombre de thread  ... 960 par bloc
		ChangerFond<<<x * y / 960, 960>>>(AddrGPU, AddrTab, InfoImg);
	}

	//Appliquer un sobel
	else if (Type == 1)
	{
		//Réservation de la mémoire GPU pour l'image résultante en x
		Erreur = cudaMalloc((void**)&AddrGPU2, x * y * 3);
		if (Erreur != cudaSuccess)
		{
			std::cout << "Allocation de la mémoire impossible\r\n";
			return Erreur;
		}

		AppliquerSobel<<<x * y * 3 / 960, 960>>>(AddrGPU, AddrGPU2, x, x * y * 3);
	}
	//**********************************************************************************
    
	
	
	
	//Vérifier si erreur pendant l'exécution du code
	Erreur = cudaGetLastError();
    if (Erreur != cudaSuccess) {
		std::cout << "Erreur d'exécution GPU : " << cudaGetErrorString(Erreur) << "\r\n";
		return Erreur;
    }
    
	//Synchroniser avec le GPU
	Erreur = cudaDeviceSynchronize();
    if (Erreur != cudaSuccess) {
		std::cout << "Erreur de synchronisation : " << cudaGetErrorString(Erreur) << "\r\n";
		return Erreur;
    }




	//******************************************************************
    //Copie des données GDDR vers DDR
	if (Type == 0) {
		Erreur = cudaMemcpy(Image, AddrGPU, x * y * 3, cudaMemcpyDeviceToHost);
		if (Erreur != cudaSuccess) {
			std::cout << "Copie vers le CPU impossible\r\n";
			return Erreur;
		}
	}
	else if (Type == 1) {
		Erreur = cudaMemcpy(Image, AddrGPU2, x * y * 3, cudaMemcpyDeviceToHost);
		if (Erreur != cudaSuccess) {
			std::cout << "Copie vers le CPU impossible\r\n";
			return Erreur;
		}
	}
	//*******************************************************************




	//Vidage du GPU
	Erreur = cudaDeviceReset();
	if (Erreur != cudaSuccess) {
		std::cout << "Ménage de la mémoire impossible\r\n";
		return Erreur;
	}


	return Erreur;
}
