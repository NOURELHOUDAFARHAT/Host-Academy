import { Outlet, useLocation, Navigate } from "react-router-dom";
import { useUserAuth } from "../../context/UserAuthContext";

const PrivateRoutesLayout = () => {
  const { user } = useUserAuth();
  const location = useLocation();
  
  // Show loading while authentication state is being determined
  if (user === undefined) {
    return <div>Loading...</div>;
  }
  
  return user ? (
    <Outlet />
  ) : (
    <Navigate to="/auth/sign-in" state={{ from: location }} replace />
  );
};

export default PrivateRoutesLayout;
