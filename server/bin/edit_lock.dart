

/// Class to handle edit locks. this has DOS where a client 
/// assigns many keys without clearing them causing memory to grow.
class EditLock {

    Map<String, DateTime> locks = {};

    //Returns true if the lock is active.
    bool get (String key) {
      final value = locks[key];
      if(value != null) {
        if(value.add(const Duration(minutes: 15)).isAfter(DateTime.now())) {
          return true;
        }
      }
      return false;
    }

    void set (String key) {
      locks[key] = DateTime.now();
    }

    void clear (String key) {
      locks.remove(key);
    }
}
