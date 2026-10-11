# Room creates WorkDatabase_Impl by reflection. R8 was deleting its
# empty constructor, so process start crashed with:
# Failed to create an instance of androidx.work.impl.WorkDatabase
-keep class * extends androidx.room.RoomDatabase {
    public <init>();
}
-keep class androidx.work.impl.** {
    public <init>();
}
