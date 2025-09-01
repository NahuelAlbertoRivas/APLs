#define MAX_FIL_COL 100

int main(){

    char res[MAX_FIL_COL][MAX_FIL_COL];

    res = miProceso();

    printf("Resultados: ");
    while(res[i]){
        printf("\n%s", res[i]);
        i++;
    }

    return 0;
}