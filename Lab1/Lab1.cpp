// David Desbiens
// Application qui traite l'arrière plan d'une image

#include "Lab1.h"

#define NomImage "scene.jpg"


/*
	scene.jpg
	B = 7;		V = 9;		R = 6;

	scene2.jpg
	B = 8;		V = 7;		R = 8;

	scene3.jpg
	B = 8;		V = 9;		R = 8;
*/



int main()
{
	Mat Image;
	_finddata_t Fichier;
	intptr_t Recherche;

	int N = 1, Compteur = 0;
	unsigned char *Sauvegarde;


	unsigned char *Filtre = new unsigned char[9];



	//Recherche les fichiers des échantillons
	g_Echantillons = new unsigned char[N * 6];
	Recherche = _findfirst("Echantillons/*.png", &Fichier);
	if (Recherche > -1) {
		CalculerMoyenne(Fichier.name, &g_Echantillons[Compteur]);
		Compteur++;
		//Prochain fichier
		while (_findnext(Recherche, &Fichier) != -1)
		{
			//Vérifier tableau
			if (Compteur >= N)
			{
				Sauvegarde = g_Echantillons;
				N += 1;
				g_Echantillons = new unsigned char[N * 6];
				for (int i = 0; i < Compteur * 6; i++)
					g_Echantillons[i] = Sauvegarde[i];
				delete(Sauvegarde);
			}

			//Calculer les résultats du fichier
			CalculerMoyenne(Fichier.name, &g_Echantillons[Compteur * 6]);
			Compteur++;
		}
	}
	else
		std::cout << "Aucun fichier trouvé";
	_findclose(Recherche);



	//Informations sur l'image
	g_Infos.Compteur = Compteur * 6;
	g_Infos.NEcartB = 7;
	g_Infos.NEcartV = 9;
	g_Infos.NEcartR = 6;


	AfficherImage();


	waitKey(0);
	destroyAllWindows();
	return 0;
}




//Afficher l'images avec le traitement
void AfficherImage() {
	Mat Image;

	/*
	VideoCapture Camera;
	Camera.open(0);

	while (waitKey(1) != 32) {
		Camera.read(Image);

		//********** Lecture de l'image #1 **********
		Image = imread(NomImage, CV_LOAD_IMAGE_COLOR);

		//Enlever le fond vert
		Analyser(Image.data, Image.cols, Image.rows, g_Echantillons, g_Infos, 0);

		//Appliquer le sobel
		//Analyser(Image.data, Image.cols, Image.rows, g_Echantillons, g_Infos, 1);

		imshow("Image", Image);

		cvCreateTrackbar2("Bleu", "Image", &g_Infos.NEcartB, 15, (CvTrackbarCallback2)on_BBarre);
		cvCreateTrackbar2("Vert", "Image", &g_Infos.NEcartV, 15, (CvTrackbarCallback2)on_VBarre);
		cvCreateTrackbar2("Rouge", "Image", &g_Infos.NEcartR, 15, (CvTrackbarCallback2)on_RBarre);
	}

	Camera.release();
	*/

	
	//********** Lecture de l'image #1 **********
	Image = imread(NomImage, CV_LOAD_IMAGE_COLOR);

	//Enlever le fond vert
	Analyser(Image.data, Image.cols, Image.rows, g_Echantillons, g_Infos, 0);

	//Appliquer le sobel
	//Analyser(Image.data, Image.cols, Image.rows, g_Echantillons, g_Infos, 1);

	imshow("Image", Image);

	cvCreateTrackbar2("Bleu", "Image", &g_Infos.NEcartB, 15, (CvTrackbarCallback2)on_BBarre);
	cvCreateTrackbar2("Vert", "Image", &g_Infos.NEcartV, 15, (CvTrackbarCallback2)on_VBarre);
	cvCreateTrackbar2("Rouge", "Image", &g_Infos.NEcartR, 15, (CvTrackbarCallback2)on_RBarre);
}

//Action des Trackbars sur l'image
void on_BBarre(int i, void *v) {
	g_Infos.NEcartB = i;
	AfficherImage();
}
void on_VBarre(int i, void *v) {
	g_Infos.NEcartV = i;
	AfficherImage();
}
void on_RBarre(int i, void *v) {
	g_Infos.NEcartR = i;
	AfficherImage();
}






//******** UTILE POUR CALCULER LA MOYENNE ET L'ÉCART TYPE D'UN ÉCHANTILLON ********
void CalculerVariance(Mat Image, unsigned char Echantillons[]) {
	int eB = 0;
	int eG = 0;
	int eR = 0;

	//Calculer la somme avec les carrés
	unsigned char *valeur = (unsigned char*)Image.data;
	for (int y = 0; y < Image.rows; y++) {
		for (int x = 0; x < Image.cols * 3; x += 3) {
			eB += (int)pow(valeur[Image.step * y + x] - Echantillons[0], 2);
			eG += (int)pow(valeur[Image.step * y + x + 1] - Echantillons[2], 2);
			eR += (int)pow(valeur[Image.step * y + x + 2] - Echantillons[4], 2);
		}
	}

	//Diviser par la somme totale
	Echantillons[1] = (unsigned char)sqrt(eB / (Image.rows * Image.cols - 1));
	Echantillons[3] = (unsigned char)sqrt(eG / (Image.rows * Image.cols - 1));
	Echantillons[5] = (unsigned char)sqrt(eR / (Image.rows * Image.cols - 1));

	//Écart type minimum de 1
	if (Echantillons[1] == 0)
		Echantillons[1] = 1;
	if (Echantillons[3] == 0)
		Echantillons[3] = 1;
	if (Echantillons[5] == 0)
		Echantillons[5] = 1;
}
void CalculerMoyenne(String f, unsigned char Echantillons[])
{
	Mat Image;
	int mB = 0, mV = 0, mR = 0;

	Image = imread("Echantillons/" + f, CV_LOAD_IMAGE_COLOR);

	//Calculer la somme
	unsigned char *valeur = (unsigned char*) Image.data;
	for (int y = 0; y < Image.rows ; y++) {
		for (int x = 0; x < Image.cols * 3 ; x += 3) {
			mB += valeur[Image.step * y + x];
			mV += valeur[Image.step * y + x + 1];
			mR += valeur[Image.step * y + x + 2];
		}
	}

	//Diviser par la somme totale
	Echantillons[0] = mB / (Image.rows * Image.cols);
	Echantillons[2] = mV / (Image.rows * Image.cols);
	Echantillons[4] = mR / (Image.rows * Image.cols);

	//Calculer l'écart type
	CalculerVariance(Image, &Echantillons[0]);
}
