import os
import re

def get_flutter_project_info():
    project_root = os.getcwd()
    info = {}

    # 1. Obtener la versión de Flutter y Dart
    print("### Información de Flutter y Dart ###")
    os.system("flutter --version")
    print("\n")

    # 2. Obtener información de Gradle y Kotlin
    print("### Información de Gradle y Kotlin ###")
    android_build_gradle_path = os.path.join(project_root, 'android', 'build.gradle.kts')
    gradle_wrapper_properties_path = os.path.join(project_root, 'android', 'gradle', 'wrapper', 'gradle-wrapper.properties')

    if os.path.exists(android_build_gradle_path):
        with open(android_build_gradle_path, 'r') as f:
            content = f.read()
            kotlin_version_match = re.search(r"kotlin\(['\"]jvm['\"]\)\s+version\s+['\"](.*?)['\"]", content) or re.search(r"id\(['\"]org\.jetbrains\.kotlin\.android['\"]\)\s+version\s+['\"](.*?)['\"]", content)
            gradle_plugin_version_match = re.search(r"id\(['\"]com\.android\.application['\"]\)\s+version\s+['\"](.*?)['\"]", content) or re.search(r"id\(['\"]com\.android\.library['\"]\)\s+version\s+['\"](.*?)['\"]", content)

            if kotlin_version_match:
                info['kotlin_version'] = kotlin_version_match.group(1)
                print(f"Versión de Kotlin (android/build.gradle): {info['kotlin_version']}")
            else:
                print("No se encontró la versión de Kotlin en android/build.gradle")

            if gradle_plugin_version_match:
                info['gradle_plugin_version'] = gradle_plugin_version_match.group(1)
                print(f"Versión del plugin de Gradle (android/build.gradle): {info['gradle_plugin_version']}")
            else:
                print("No se encontró la versión del plugin de Gradle en android/build.gradle")
    else:
        print(f"Archivo no encontrado: {android_build_gradle_path}")

    if os.path.exists(gradle_wrapper_properties_path):
        with open(gradle_wrapper_properties_path, 'r') as f:
            content = f.read()
            gradle_distribution_match = re.search(r"distributionUrl=https\\://services\.gradle\.org/distributions/gradle-(.*?)-all\.zip", content)
            if gradle_distribution_match:
                info['gradle_distribution_version'] = gradle_distribution_match.group(1)
                print(f"Versión de distribución de Gradle (android/gradle/wrapper/gradle-wrapper.properties): {info['gradle_distribution_version']}")
            else:
                print("No se encontró la versión de distribución de Gradle en android/gradle/wrapper/gradle-wrapper.properties")
    else:
        print(f"Archivo no encontrado: {gradle_wrapper_properties_path}")

    print("\n")
    print("### Contenido de android/build.gradle ###")
    if os.path.exists(android_build_gradle_path):
        with open(android_build_gradle_path, 'r') as f:
            print(f.read())
    else:
        print(f"Archivo no encontrado: {android_build_gradle_path}")

    print("\n")
    print("### Contenido de android/gradle/wrapper/gradle-wrapper.properties ###")
    if os.path.exists(gradle_wrapper_properties_path):
        with open(gradle_wrapper_properties_path, 'r') as f:
            print(f.read())
    else:
        print(f"Archivo no encontrado: {gradle_wrapper_properties_path}")

if __name__ == "__main__":
    get_flutter_project_info()