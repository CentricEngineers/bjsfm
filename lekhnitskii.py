import numpy as np
import fourier_series as fs


class Hole:
    """
    Parent class for defining a hole in an anisotropic plate for laminated composites

    Attributes
    ----------
    :ivar r: the hole radius
    :ivar a: inverse a-matrix of the laminate
    :ivar h: thickness of the laminate
    :ivar mu1: real part of first root of characteristic equation
    :ivar mu2: real part of second root of characteristic equation
    :ivar mu1_bar: imaginary part of first root of characteristic equation
    :ivar mu2_bar: imaginary part of second root of characteristic equation


    References
    ----------
    .. [1] Esp, B. (2007). *Stress distribution and strength prediction of composite
           laminates with multiple holes* (PhD thesis). Retrieved from
           https://rc.library.uta.edu/uta-ir/bitstream/handle/10106/767/umi-uta-1969.pdf?sequence=1&isAllowed=y
    .. [2] Lekhnitskii, S., Tsai, S., & Cheron, T. (1987). *Anisotropic plates* (2nd ed.).
           New York: Gordon and Breach science.
    .. [3] Garbo, S. and Ogonowski, J. (1981) *Effect of variances and manufacturing
           tolerances on the design strength and life of mechanically fastened
           composite joints* (Vol. 1,2,3). AFWAL-TR-81-3041.
    .. [4] Waszczak, J.P. and Cruse T.A. (1973) *A synthesis procedure for mechanically
           fastened joints in advanced composite materials* (Vol. II). AFML-TR-73-145.
    """

    def __init__(self, diameter, thickness, a_inv):
        """
        Constructor

        :param diameter: hole diameter
        :param thickness: laminate thickness
        :param a_inv: <np.array> inverse laminate A-matrix
        """
        self.r = diameter/2.
        self.a = a_inv
        self.h = thickness
        self.mu1, self.mu2, self.mu1_bar, self.mu2_bar = self.roots()

    def roots(self):
        """
        Finds the roots to the characteristic equation [Eq. A.2, Ref. 1]

        :raises: ValueError if roots cannot be found
        """
        a11 = self.a[0, 0]
        a12 = self.a[0, 1]
        a16 = self.a[0, 2]
        a22 = self.a[1, 1]
        a26 = self.a[1, 2]
        a66 = self.a[2, 2]

        roots = np.roots([a11, -2 * a16, (2 * a12 + a66), -2 * a26, a22])

        if np.imag(roots[0]) >= 0.0:
            mu1 = roots[0]
            mu1_bar = roots[1]
        elif np.imag(roots[1]) >= 0.0:
            mu1 = roots[1]
            mu1_bar = roots[0]
        else:
            raise ValueError("mu1 cannot be solved")

        if np.imag(roots[2]) >= 0.0:
            mu2 = roots[2]
            mu2_bar = roots[3]
        elif np.imag(roots[3]) >= 0.0:
            mu2 = roots[3]
            mu2_bar = roots[2]
        else:
            raise ValueError("mu2 cannot be solved")

        return mu1, mu2, mu1_bar, mu2_bar

    def ksi_1(self, z1):
        """
        Calculates the first mapping parameter [Eq. A.4 & Eq. A.5, Ref. 1]
        """
        mu1 = self.mu1
        a = self.r
        b = self.r

        ksi_1_pos = (z1 + np.sqrt(z1 * z1 - a * a - mu1 * mu1 * b * b)) / (a - 1j * mu1 * b)
        ksi_1_neg = (z1 - np.sqrt(z1 * z1 - a * a - mu1 * mu1 * b * b)) / (a - 1j * mu1 * b)

        if np.abs(ksi_1_pos) >= 1.0:
            ksi_1 = ksi_1_pos
            sign_1 = 1
        elif np.abs(ksi_1_neg) >= 1.0:
            ksi_1 = ksi_1_neg
            sign_1 = -1
        else:
            raise ValueError(
                "ksi_1 unsolvable:\n ksi_1_pos={0}, ksi_1_neg={1}".format(
                    ksi_1_pos, ksi_1_neg))

        return ksi_1, sign_1

    def ksi_2(self, z2):
        """
        Calculates the second mapping parameter [Eq. A.4 & Eq. A.5, Ref. 1]
        """
        mu2 = self.mu2
        a = self.r
        b = self.r

        ksi_2_pos = (z2 + np.sqrt(z2 * z2 - a * a - mu2 * mu2 * b * b)) / (a - 1j * mu2 * b)
        ksi_2_neg = (z2 - np.sqrt(z2 * z2 - a * a - mu2 * mu2 * b * b)) / (a - 1j * mu2 * b)

        if np.abs(ksi_2_pos) >= 1.0:
            ksi_2 = ksi_2_pos
            sign_2 = 1
        elif np.abs(ksi_2_neg) >= 1.0:
            ksi_2 = ksi_2_neg
            sign_2 = -1
        else:
            raise ValueError(
                "ksi_1 unsolvable:\n ksi_1_pos={0}, ksi_1_neg={1}".format(
                    ksi_2_pos, ksi_2_neg))

        return ksi_2, sign_2

    # @abc.abstractclassmethod()
    def phi_1_prime(self, z1):
        raise NotImplementedError("You must implement this function.")

    # @abc.abstractclassmethod()
    def phi_2_prime(self, z2):
        raise NotImplementedError("You must implement this function.")

    def stress(self, x, y):
        """
        Calculates the stress at point (x, y) in the plate.
        [Eq. 8.2, Ref. 2]
        """
        mu1 = self.mu1
        mu2 = self.mu2

        z1 = x + mu1 * y
        z2 = x + mu2 * y

        phi_1_prime = self.phi_1_prime(z1)
        phi_2_prime = self.phi_2_prime(z2)

        sx = 2.0 * np.real(mu1 * mu1 * phi_1_prime + mu2 * mu2 * phi_2_prime)
        sy = 2.0 * np.real(phi_1_prime + phi_2_prime)
        sxy = -2.0 * np.real(mu1 * phi_1_prime + mu2 * phi_2_prime)

        return np.array([sx, sy, sxy])


class UnloadedHole(Hole):
    """
    Class for defining an unloaded hole in an anisotropic homogeneous plate

    Notes
    -----
        farfield forces (Nx, Ny, Nxy) are force/unit length
    """

    def __init__(self, loads, diameter, thickness, a_inv):
        """
        Class constructor.

        :param loads: <array-like> [Nx, Ny, Nxy] force / unit length
        :param diameter: hole diameter
        :param thickness: laminate thickness
        :param a_inv: inverse laminate A-matrix
        """
        super().__init__(diameter, thickness, a_inv)
        self.applied_stress = np.array(loads) / self.h

    def alpha(self):
        """
        Calculates the alpha loading term. [Eq. A.7, Ref. 1]
        """
        sy = self.applied_stress[1]
        sxy = self.applied_stress[2]
        r = self.r

        return 1j * sxy * r / 2 - sy * r / 2

    def beta(self):
        """
        Calculates the beta loading term. [Eq. A.7, Ref. 1]
        """
        sx = self.applied_stress[0]
        sxy = self.applied_stress[2]
        r = self.r

        return sxy * r / 2 - 1j * sx * r / 2

    def phi_1_prime(self, z1):
        """
        Calculates derivative of the stress function. [Eq. A.8, Ref. 1]
        """
        a = self.r
        b = self.r
        mu1 = self.mu1
        mu2 = self.mu2
        alpha = self.alpha()
        beta = self.beta()
        ksi_1, sign_1 = self.ksi_1(z1)

        C1 = (beta - mu2 * alpha) / (mu1 - mu2)
        eta1 = sign_1 * np.sqrt(z1 * z1 - a * a - mu1 * mu1 * b * b)
        kappa1 = 1 / (a - 1j * mu1 * b)

        return -C1 / (ksi_1 ** 2) * (1 + z1 / eta1) * kappa1

    def phi_2_prime(self, z2):
        """
        Calculates derivative of the stress function. [Eq. A.8, Ref. 1]
        """
        a = self.r
        b = self.r
        mu1 = self.mu1
        mu2 = self.mu2
        alpha = self.alpha()
        beta = self.beta()
        ksi_2, sign_2 = self.ksi_2(z2)

        C2 = -(beta - mu1 * alpha) / (mu1 - mu2)
        eta2 = sign_2 * np.sqrt(z2 * z2 - a * a - mu2 * mu2 * b * b)
        kappa2 = 1 / (a - 1j * mu2 * b)

        return -C2 / (ksi_2 ** 2) * (1 + z2 / eta2) * kappa2

    def stress(self, x, y):
        """
        Calculates the laminate average stress at a point (x, y).
        [Eq. A.9, Ref. 1]
        """
        sx, sy, sxy = super().stress(x, y)

        sx_app = self.applied_stress[0]
        sy_app = self.applied_stress[1]
        sxy_app = self.applied_stress[2]

        return np.array([sx + sx_app, sy + sy_app, sxy + sxy_app])


class LoadedHole(Hole):
    """
    Class for defining a loaded hole in an anisotropic homogeneous plate
    with bearing force applied [Fig. 10, Ref. [4]_].
    """
    FOURIER_TERMS = 45  # number of fourier series terms [Ref. 3]

    def __init__(self, load, diameter, thickness, a_matrix):
        """
        :param load: bearing force
        :param diameter: Hole diameter
        :param thickness: laminate thickness
        :param a_matrix: inverse laminate A-matrix
        """
        super().__init__(diameter, thickness, a_matrix)
        self.p = load
        self.A, self.A_bar, self.B, self.B_bar = self.solve_constants()

    def alphas(self):
        """
        :param N: <int> number of fourier series terms
        :return: alpha coefficients for x-dir only bearing loads
        """
        h = self.h
        p = self.p
        # N = self.FOURIER_TERMS

        # return -p / (np.pi * h) * fs.x_dir_alpha_coefficients(N)
        # hard coded alpha values used for runtime optimization
        return -p / (np.pi * h) * fs.x_dir_alphas

    def betas(self):
        """
        :param N: <int> number of fourier series terms
        :return: beta coefficients for x-dir only bearing loads
        """
        h = self.h
        p = self.p
        N = self.FOURIER_TERMS
        m = np.arange(1, N + 1)

        # return 4 * p / (np.pi * m**2 * h) * fs.x_dir_beta_coefficients(N)
        # hard coded beta values used for runtime optimization
        return 4 * p / (np.pi * m**2 * h) * fs.x_dir_betas

    def solve_constants(self):
        """
        Eq. 37.5 [ref. 2] expanding complex terms and resolving for A, A_bar, B and B_bar (setting Py equal to zero)
        """
        R1, R2 = np.real(self.mu1), np.imag(self.mu1)
        R3, R4 = np.real(self.mu2), np.imag(self.mu2)
        p = self.p
        h = self.h
        a11 = self.a[0, 0]
        a12 = self.a[0, 1]
        a22 = self.a[1, 1]
        a16 = self.a[0, 2]
        pi = np.pi

        mu_mat = np.array([[0., 1, 0., 1.],
                           [R2, R1, R4, R3],
                           [2*R1*R2, (R1**2 - R2**2), 2*R3*R4, (R3**2 - R4**2)],
                           [R2/(R1**2 + R2**2), -R1/(R1**2 + R2**2), R4/(R3**2 + R4**2), -R3/(R3**2 + R4**2)]])

        load_vec = p/(4.*pi*h) * np.array([[0.],
                                           [1.],
                                           [a16/a11],
                                           [a12/a22]])

        A1, A2, B1, B2 = np.dot(np.linalg.inv(mu_mat), load_vec)
        return A1, A2, B1, B2

    def phi_1_prime(self, z1):
        """
        Calculates derivative of the stress function. [Eq. 37.6, Ref. 2]
        """
        mu1 = self.mu1
        mu2 = self.mu2
        a = self.r
        b = self.r
        A = self.A + 1j * self.A_bar
        N = self.FOURIER_TERMS
        ksi_1, sign_1 = self.ksi_1(z1)

        eta_1 = sign_1 * np.sqrt(z1 * z1 - a * a - b * b * mu1 * mu1)

        m = np.arange(1, N + 1)
        alphas = self.alphas()
        betas = self.betas()

        return 1 / eta_1 * (A - np.sum(m * (betas - mu2 * alphas) / (mu1 - mu2) / ksi_1 ** m))

    def phi_2_prime(self, z2):
        """
        Calculates derivative of the stress function. [Eq. 37.6, Ref. 2]
        """
        mu1 = self.mu1
        mu2 = self.mu2
        a = self.r
        b = self.r
        B = self.B + 1j * self.B_bar
        N = self.FOURIER_TERMS
        ksi_2, sign_2 = self.ksi_2(z2)

        eta_2 = sign_2 * np.sqrt(z2 * z2 - a * a - b * b * mu2 * mu2)

        m = np.arange(1, N + 1)
        alphas = self.alphas()
        betas = self.betas()

        return 1 / eta_2 * (B + np.sum(m * (betas - mu1 * alphas) / (mu1 - mu2) / ksi_2 ** m))


