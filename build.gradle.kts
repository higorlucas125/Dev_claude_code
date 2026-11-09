// Arquivo de build raiz: só declara os plugins; cada módulo aplica o que precisa.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.compose) apply false
}
