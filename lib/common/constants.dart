/// App-wide constants shared by services, providers, and screens.
library;

const String kAppName = 'Mova';
const String kStoragePrefix = 'mova.v1.';
const int kSchemaVersion = 1;

const int kDefaultSessionMinutes = 55;
const int kMinTrainingDays = 1;
const int kMaxTrainingDays = 7;
const int kDefaultTrainingDays = 3;
const int kMaxRoutineExercises = 20;

const int kMinAge = 13;
const int kMaxAge = 120;

const double kMinWeightKg = 30;
const double kMaxWeightKg = 250;
const double kWeightStepKg = 0.5;

const double kMinHeightCm = 120;
const double kMaxHeightCm = 230;
const double kHeightStepCm = 1;

const String kProfileKey = '${kStoragePrefix}profile';
const String kSettingsKey = '${kStoragePrefix}settings';
const String kPlanKey = '${kStoragePrefix}plan';
const String kActiveSessionKey = '${kStoragePrefix}activeSession';
const String kWorkoutsKey = '${kStoragePrefix}workouts';
const String kRoutinesKey = '${kStoragePrefix}routines';
const String kPrsKey = '${kStoragePrefix}prs';
const String kSocialKey = '${kStoragePrefix}social';
const String kStepsKey = '${kStoragePrefix}steps';
const String kWeightsKey = '${kStoragePrefix}weights';
const String kWellnessKey = '${kStoragePrefix}wellness';
const String kPhotosKey = '${kStoragePrefix}photos';
const String kOnboardingKey = '${kStoragePrefix}onboarding';
