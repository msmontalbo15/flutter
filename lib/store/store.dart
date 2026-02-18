import 'package:redux/redux.dart';
import 'app_state.dart';
import 'auth/auth_reducer.dart';

Store<AppState> createStore() {
  return Store(
    (state, action) => AppState(auth: authReducer(state.auth, action)),
    initialState: AppState.initial(),
  );
}
